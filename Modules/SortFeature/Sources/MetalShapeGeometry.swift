import CoreGraphics
import Foundation

/// Selects which per-layout position formula `shape_vertex` (`ShapeRenderer.metal`) applies to a
/// given draw call — the shader-side counterpart to `MetalShapeLayout.geometryKind`. Raw values
/// match the MSL `switch` cases in `resolveShapeGeometry` exactly; both sides must stay in sync by
/// hand, the same way `easeInOutCubic`/`hueRampColor` already do.
enum MetalShapeGeometryKind: Int32 {
  case disparityBarGraph = 0
  case rainbow = 1
  case sineWave = 2
  case pixelMesh = 3
  case scatterPlot = 4
  case waveDots = 5
  case spiralDots = 6
  case disparityDots = 7
  case hoopStack = 8
}

/// The CPU reference implementation of `AnimatedField.h`'s `resolveShapeGeometry` — byte-for-byte
/// (well, formula-for-formula) the same per-layout position math each `MetalShapeLayout` used to
/// compute directly, now relocated into the vertex shader and run once per vertex per frame
/// instead of once per touched slot per operation. Used ONLY by `MetalShapeRenderer
/// .resolvedInstances(at:)` (a test seam) — never on a per-frame production path, matching every
/// other `resolveAnimated*`-family CPU mirror in this codebase. Takes PIXEL-space `viewportSize`
/// (not points) and a raw, un-normalized `value` — `writeInstance` no longer converts a layout's
/// points-space geometry to pixels itself (there's no geometry left there to convert); this
/// function (and its MSL twin) does the points-to-pixels-equivalent math directly in pixel space,
/// substituting `viewportSize` for what each original formula called `canvasSize`.
///
/// `slot` (the raw `instanceID`) and `arrayIndex` (`MetalShapeLayout.arrayIndex(forSlot:count:)`'s
/// CPU-resolved result, unchanged by this port) are DELIBERATELY separate parameters: every layout
/// except `PixelMeshMetalLayout` uses `arrayIndex` for its formula, but `PixelMeshMetalLayout`'s
/// grid-cell placement is a pure function of `slot` alone (which array index's VALUE ends up in
/// that cell is a separate, still-CPU-side concern this geometry port doesn't touch).
func resolveShapeGeometry(
  kind: MetalShapeGeometryKind, slot: Int32, arrayIndex: Int32, value: Float,
  arrayCount: Float, valueRangeLowerBound: Float, valueRangeSpan: Float,
  viewportSize: SIMD2<Float>, scale: Float
) -> (origin: SIMD2<Float>, size: SIMD2<Float>) {
  let index = Float(arrayIndex)
  let normalized =
    valueRangeSpan > 0 ? (value - valueRangeLowerBound) / valueRangeSpan : 1.0

  switch kind {
  case .disparityBarGraph:
    let barWidth = viewportSize.x / arrayCount
    let disp = (1 + sin(.pi * (value - index) / arrayCount)) * 0.5
    let height = viewportSize.y * disp
    return (
      SIMD2(index * barWidth, viewportSize.y - height), SIMD2(barWidth, height)
    )

  case .rainbow:
    let barWidth = viewportSize.x / arrayCount
    let height = viewportSize.y * normalized
    return (
      SIMD2(index * barWidth, viewportSize.y - height), SIMD2(barWidth, height)
    )

  case .sineWave:
    let columnWidth = viewportSize.x / arrayCount
    let centerY = viewportSize.y / 2
    let amplitude = viewportSize.y * 0.4
    let y = centerY - amplitude * sin(2 * .pi * normalized)
    let barThickness = Float(5) * scale
    return (
      SIMD2(index * columnWidth, y - barThickness / 2), SIMD2(columnWidth, barThickness)
    )

  case .pixelMesh:
    let side = Float(Int(arrayCount.squareRoot().rounded(.up)))
    guard side > 0 else { return (.zero, .zero) }
    let cellWidth = viewportSize.x / side
    let cellHeight = viewportSize.y / side
    let gridX = Float(Int(slot) % Int(side))
    let gridY = Float(Int(slot) / Int(side))
    return (SIMD2(gridX * cellWidth, gridY * cellHeight), SIMD2(cellWidth, cellHeight))

  case .scatterPlot:
    let columnWidth = viewportSize.x / arrayCount
    let dotDiameter = Float(6) * scale
    let radius = dotDiameter / 2
    let centerX = index * columnWidth + columnWidth / 2
    let centerY = radius + (viewportSize.y - 2 * radius) * (1 - normalized)
    return (
      SIMD2(centerX - radius, centerY - radius), SIMD2(dotDiameter, dotDiameter)
    )

  case .waveDots:
    let columnWidth = viewportSize.x / arrayCount
    let dotDiameter = Float(6) * scale
    let radius = dotDiameter / 2
    let verticalCenter = viewportSize.y / 2
    let amplitude = viewportSize.y / 2 - radius
    let centerX = index * columnWidth + columnWidth / 2
    let centerY = verticalCenter + amplitude * sin(2 * .pi * normalized)
    return (
      SIMD2(centerX - radius, centerY - radius), SIMD2(dotDiameter, dotDiameter)
    )

  case .spiralDots:
    let center = SIMD2(viewportSize.x / 2, viewportSize.y / 2)
    let radius = min(viewportSize.x, viewportSize.y) / 2.5
    let angle: Float = .pi * (2 * index / arrayCount - 0.5)
    let distance = normalized * radius
    let dotDiameter = Float(6) * scale
    let centerPoint = SIMD2(center.x + distance * cos(angle), center.y + distance * sin(angle))
    return (centerPoint - dotDiameter / 2, SIMD2(dotDiameter, dotDiameter))

  case .disparityDots:
    let center = SIMD2(viewportSize.x / 2, viewportSize.y / 2)
    let radius = min(viewportSize.x, viewportSize.y) / 2.5
    let dotDiameter = Float(6) * scale
    let dotRadius = dotDiameter / 2
    let disp = (1 + cos(.pi * (value - index) / (arrayCount * 0.5))) * 0.5
    let theta: Float = .pi * (2 * index / arrayCount - 0.5)
    let centerPoint = SIMD2(
      center.x + disp * radius * cos(theta), center.y + disp * radius * sin(theta))
    return (centerPoint - dotRadius, SIMD2(dotDiameter, dotDiameter))

  case .hoopStack:
    let centerX = viewportSize.x / 2
    let baseRadiusX = min(viewportSize.y / 6, viewportSize.x / 2)
    let baseRadiusY = viewportSize.y / 18
    let y: Float =
      arrayCount > 1
      ? baseRadiusY + (viewportSize.y - 2 * baseRadiusY) * index / (arrayCount - 1)
      : viewportSize.y / 2
    let scaleFactor = 0.2 + 0.8 * normalized
    let radiusX = scaleFactor * baseRadiusX
    let radiusY = scaleFactor * baseRadiusY
    return (
      SIMD2(centerX - radiusX, y - radiusY), SIMD2(2 * radiusX, 2 * radiusY)
    )
  }
}

/// The `MetalTriangleLayout` counterpart to `MetalShapeGeometryKind` — a separate, independent
/// enum sharing the SAME `MetalAnimationUniforms.geometryKind` field (harmless: `shape_vertex`/
/// `triangle_vertex` are different shader entry points, each interpreting the field only within
/// its own draw calls, so the two enums' overlapping raw values never actually collide).
enum MetalTriangleGeometryKind: Int32 {
  case colorCircle = 0
  case disparityCircle = 1
  case spiral = 2
}

/// CPU reference implementation of `AnimatedField.h`'s `resolveTriangleGeometry` — see
/// `resolveShapeGeometry`'s own doc comment for the full rationale (test-seam only, never a
/// per-frame production path). `p0` (every wedge's shared center point) isn't computed by either
/// the CPU or a per-instance GPU field at all anymore — it's always `viewportSize/2`, cheap enough
/// to inline directly wherever it's needed instead of tracking/easing/storing it, since it never
/// varies per-instance and only changes on resize (a full `reset()`, which repaints everything
/// anyway).
///
/// `value`/`previousValue` are both raw, un-normalized values — `MetalTriangleRenderer
/// .writeInstance` supplies `previousValue` generically (`values[(arrayIndex - 1 + arrayCount) %
/// arrayCount]`) for every layout, not just the two that actually use it; `colorCircle`'s branch
/// simply never reads either parameter (its position depends only on `arrayIndex`).
func resolveTriangleGeometry(
  kind: MetalTriangleGeometryKind, arrayIndex: Int32, value: Float, previousValue: Float,
  arrayCount: Float, valueRangeLowerBound: Float, valueRangeSpan: Float, viewportSize: SIMD2<Float>
) -> (p0: SIMD2<Float>, p1: SIMD2<Float>, p2: SIMD2<Float>) {
  let index = Float(arrayIndex)
  let previousIndex = (index - 1 + arrayCount).truncatingRemainder(dividingBy: arrayCount)
  let center = SIMD2(viewportSize.x / 2, viewportSize.y / 2)

  func angle(_ position: Float) -> Float { .pi * (2 * position / arrayCount - 0.5) }
  func unitVector(_ theta: Float) -> SIMD2<Float> { SIMD2(cos(theta), sin(theta)) }
  func normalize(_ v: Float) -> Float {
    valueRangeSpan > 0 ? (v - valueRangeLowerBound) / valueRangeSpan : 1
  }

  let p0 = center
  let p1: SIMD2<Float>
  let p2: SIMD2<Float>

  switch kind {
  case .colorCircle:
    // Position-only — radius is fixed, angle depends only on index, never on value.
    let radius = min(viewportSize.x, viewportSize.y) / 2.75
    p1 = center + radius * unitVector(angle(previousIndex))
    p2 = center + radius * unitVector(angle(index))

  case .disparityCircle:
    let radius = min(viewportSize.x, viewportSize.y) / 2.5
    func disp(_ v: Float, _ i: Float) -> Float {
      (1 + cos(.pi * (v - i) / (arrayCount * 0.5))) * 0.5
    }
    p1 = center + disp(previousValue, previousIndex) * radius * unitVector(angle(previousIndex))
    p2 = center + disp(value, index) * radius * unitVector(angle(index))

  case .spiral:
    let radius = min(viewportSize.x, viewportSize.y) / 2.5
    func mult(_ n: Float) -> Float { 1 - (1 - n) * (1 - n) }
    p1 = center + mult(normalize(previousValue)) * radius * unitVector(angle(previousIndex))
    p2 = center + mult(normalize(value)) * radius * unitVector(angle(index))
  }
  return (p0, p1, p2)
}

/// CPU reference implementation of `AnimatedField.h`'s `resolveChordGeometry` —
/// `MetalDisparityChordsRenderer`'s own geometry (no `MetalShapeGeometryKind`/
/// `MetalTriangleGeometryKind`-style selector needed: it's the only line-based renderer, so
/// `line_vertex` always applies this one formula unconditionally). `index` is always `instanceID`
/// directly (no resampling, no reversed draw order — `MetalDisparityChordsRenderer` never
/// overrides `arrayIndex(forSlot:)`), so unlike the shape/triangle families this needs no separate
/// stored `arrayIndex` field in the GPU buffer at all.
func resolveChordGeometry(
  index: Int32, value: Float, arrayCount: Float, viewportSize: SIMD2<Float>
) -> (start: SIMD2<Float>, end: SIMD2<Float>) {
  let center = SIMD2(viewportSize.x / 2, viewportSize.y / 2)
  let radius = min(viewportSize.x, viewportSize.y) / 2.5
  func angle(_ position: Float) -> Float { .pi * (2 * position / arrayCount - 0.5) }
  let fromAngle = angle(Float(index))
  let toAngle = angle(value)
  let start = center + radius * SIMD2(cos(fromAngle), sin(fromAngle))
  let end = center + radius * SIMD2(cos(toAngle), sin(toAngle))
  return (start, end)
}
