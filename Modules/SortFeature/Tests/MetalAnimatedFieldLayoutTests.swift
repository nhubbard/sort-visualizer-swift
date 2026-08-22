import Testing

@testable import SortFeature

/// Regression coverage for a real bug this project hit: `AnimatedFloat2`'s raw (unpadded) size
/// used to be smaller than its own alignment-padded stride, and Swift's nested-struct field-offset
/// computation uses raw `size` while MSL/C always uses the alignment-padded `sizeof` — so a field
/// following an `AnimatedFloat2` (like `MetalLineInstance.thickness`) could land at a different
/// byte offset in Swift than the shader expected, silently corrupting whichever fields came after
/// it. Fixed via an explicit padding field making `size == stride`. `AnimatedColorSource`/
/// `AnimatedMarkerColor` (the color-resolution-on-GPU structs) were designed from the start to be
/// all 4-byte-aligned scalars specifically to avoid this class of bug entirely — these tests assert
/// that invariant directly for every animated-field type, plus the resulting stride of every
/// GPU-buffer struct that embeds them, so a future field reordering/addition that reintroduces a
/// similar gap fails loudly here instead of as a rendering bug only visible via pixel readback (see
/// `MetalPolygonRendererTests.linePipelineRendersAlongItsOwnMidpoint`, which is what actually
/// caught the original bug).
@Suite
struct MetalAnimatedFieldLayoutTests {
  @Test
  func animatedFloat2HasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedFloat2>.size == MemoryLayout<AnimatedFloat2>.stride)
    #expect(MemoryLayout<AnimatedFloat2>.stride == 24)
  }

  @Test
  func animatedColorSourceHasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedColorSource>.size == MemoryLayout<AnimatedColorSource>.stride)
    #expect(MemoryLayout<AnimatedColorSource>.stride == 20)
  }

  @Test
  func animatedMarkerColorHasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedMarkerColor>.size == MemoryLayout<AnimatedMarkerColor>.stride)
    #expect(MemoryLayout<AnimatedMarkerColor>.stride == 12)
  }

  /// `AnimatedFloat` — the scalar counterpart to `AnimatedFloat2`, added for `MetalBarRenderer`'s
  /// GPU-geometry port. All 3 fields are already 4-byte-aligned scalars (no `SIMD` members), so —
  /// like `AnimatedColorSource`/`AnimatedMarkerColor` — this carries none of `AnimatedFloat2`'s
  /// padding risk; asserted anyway as a permanent tripwire, same discipline as every other type
  /// here.
  @Test
  func animatedFloatHasNoInternalPadding() {
    #expect(MemoryLayout<AnimatedFloat>.size == MemoryLayout<AnimatedFloat>.stride)
    #expect(MemoryLayout<AnimatedFloat>.stride == 12)
  }

  /// Grew from 80 to 112 (5 new fields total: `arrayCount`/`valueRangeLowerBound`/`valueRangeSpan`
  /// for `MetalBarRenderer`'s GPU-geometry port, then `scale`/`geometryKind` for the
  /// `MetalShapeRenderer` family's) — the struct's own alignment stays 16 (from its
  /// `SIMD4<Float>` color fields), so the 5 new 4-byte fields land at raw offset 100, padded up to
  /// the next 16-byte boundary.
  @Test
  func metalAnimationUniformsStride() {
    #expect(MemoryLayout<MetalAnimationUniforms>.stride == 112)
  }

  /// Shrank from 64 to 24 (`{origin: AnimatedFloat2, size: AnimatedFloat2, color:
  /// AnimatedMarkerColor}` → `{value: AnimatedFloat, color: AnimatedMarkerColor}`) — Bar no longer
  /// stores a precomputed screen rect at all, only the raw value the shader derives one from.
  @Test
  func barInstanceStride() {
    #expect(MemoryLayout<MetalBarRenderer.BarInstance>.stride == 24)
  }

  /// Shrank from 72 to 36 (`{origin: AnimatedFloat2, size: AnimatedFloat2, color:
  /// AnimatedColorSource}` → `{arrayIndex: Int32, value: AnimatedFloat, color:
  /// AnimatedColorSource}`) — every `MetalShapeLayout` now supplies a raw value instead of a
  /// precomputed rect; `shape_vertex` derives the actual on-screen geometry itself.
  @Test
  func shapeGPUInstanceStride() {
    #expect(MemoryLayout<MetalShapeGPUInstance>.stride == 36)
  }

  /// Shrank from 96 to 48 (`{p0: AnimatedFloat2, p1: AnimatedFloat2, p2: AnimatedFloat2, color:
  /// AnimatedColorSource}` → `{arrayIndex: Int32, value: AnimatedFloat, previousValue:
  /// AnimatedFloat, color: AnimatedColorSource}`) — `triangle_vertex` now derives all 3 points
  /// itself via `resolveTriangleGeometry`, same rationale as `shapeGPUInstanceStride`'s shrink.
  @Test
  func triangleGPUInstanceStride() {
    #expect(MemoryLayout<MetalTriangleGPUInstance>.stride == 48)
  }

  /// Shrank from 72 to 36 (`{start: AnimatedFloat2, end: AnimatedFloat2, thickness: Float, color:
  /// AnimatedColorSource}` → `{value: AnimatedFloat, thickness: Float, color:
  /// AnimatedColorSource}`) — `line_vertex` now derives both endpoints itself via
  /// `resolveChordGeometry`, same rationale as `shapeGPUInstanceStride`'s shrink. The original
  /// Swift/MSL packing bug this suite guards against (see the suite's own doc comment) no longer
  /// has an `AnimatedFloat2` in this struct to trigger it, but the assertion stays as a permanent
  /// tripwire.
  @Test
  func lineInstanceStride() {
    #expect(MemoryLayout<MetalLineInstance>.stride == 36)
  }

  @Test
  func hanoiOriginHasNoInternalPadding() {
    #expect(MemoryLayout<HanoiOrigin>.size == MemoryLayout<HanoiOrigin>.stride)
    #expect(MemoryLayout<HanoiOrigin>.stride == 32)
  }

  /// Shrank from 64 to 56 (`{origin: HanoiOrigin, size: SIMD2<Float>, color: AnimatedColorSource}`
  /// → `{origin: HanoiOrigin, color: AnimatedColorSource}`) — `hanoi_vertex` now derives the block's
  /// size itself (`resolveHanoiGeometry`), same rationale as every other GPU-geometry port's shrink.
  @Test
  func hanoiInstanceStride() {
    #expect(MemoryLayout<HanoiInstance>.stride == 56)
  }
}
