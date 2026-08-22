import Foundation

/// The CPU reference implementation of `ShapeRenderer.metal`'s `hanoiTowerCount`/
/// `resolveHanoiGeometry` — see `resolveShapeGeometry`'s own doc comment for the full rationale
/// (test-seam only, never a per-frame production path).
///
/// `MetalHanoiTowersRenderer.towerCount(for:)` is a pure function of `arrayCount` alone (`max(3,
/// min(16, round(sqrt(count))))`), so unlike every other layout's `geometryKind`-selected formula,
/// Hanoi's shader needs no per-`Layout` selector at all — it can just recompute `towerCount`/
/// `maxDepth` itself from `uniforms.arrayCount`, the same value already threaded through for every
/// other renderer. Metal's `round()` rounds halfway cases away from zero, matching Swift's default
/// `.rounded()` — the two must stay in exact agreement for any array size this app actually
/// supports (up to `AlgorithmMetadata.maxReasonableArraySize`, 8192, verified via
/// `MetalHanoiTowersRendererTests`'s existing tower/depth-assignment coverage, which now also
/// exercises this indirectly). Capped at 16, not 8 — see `towerCount(for:)`'s own doc comment for
/// why: below 16, `maxDepth` (and thus the obstacle-lifting choreography's worst-case per-swap
/// cost) grows unbounded well within this app's real supported array-size range.
func hanoiTowerCount(forArrayCount arrayCount: Float) -> Float {
  let raw = arrayCount.squareRoot().rounded()
  return min(16, max(3, raw))
}

/// Turns an abstract (tower, depth) coordinate — NOT a pixel position — into the actual on-screen
/// rect `hanoi_vertex` draws. `towerDepth.x` is always tower's integral index; `towerDepth.y` is
/// depth, which may be fractional (mid-blend between two integral depths — see
/// `HanoiOrigin`'s own doc comment on why this is safe: `blockPosition`'s formula is affine linear
/// in both components, so linearly blending two (tower, depth) pairs and then applying this
/// formula is mathematically identical to blending the two formula OUTPUTS directly, which is what
/// the pre-port CPU code did) or `>= maxDepth` (a "parked" obstacle slot, stacked above the tower's
/// own legitimate contents — see `MetalHanoiTowersRenderer.parkedCoordinate`'s doc comment).
func resolveHanoiGeometry(
  towerDepth: SIMD2<Float>, arrayCount: Float, viewportSize: SIMD2<Float>
) -> (origin: SIMD2<Float>, size: SIMD2<Float>) {
  let towerCount = hanoiTowerCount(forArrayCount: arrayCount)
  let maxDepth = max(1, (arrayCount / towerCount).rounded(.up))
  let towerWidth = viewportSize.x / towerCount
  let blockHeight = viewportSize.y / maxDepth
  let origin = SIMD2(
    towerDepth.x * towerWidth + towerWidth * 0.1,
    viewportSize.y - (towerDepth.y + 1) * blockHeight)
  let size = SIMD2(towerWidth * 0.8, blockHeight * 0.9)
  return (origin, size)
}
