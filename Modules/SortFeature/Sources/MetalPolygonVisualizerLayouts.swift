import CoreGraphics
import Foundation

/// One `MetalTriangleLayout` per wedge-shaped visualizer. Each `instance(atSlot:...)` is a direct,
/// line-for-line port of the matching `Visualizer.draw(_:)`'s per-index math, just returning one
/// `MetalTriangleInstance` instead of appending a `.polygon` `DrawCommand` — see
/// `MetalTriangleLayout`'s own doc comment for why geometry here is in points, and why
/// `DisparityCircleMetalLayout`/`SpiralMetalLayout` override `slots(forIndex:)` (their wedges
/// depend on a NEIGHBOR's value, `ColorCircleMetalLayout`'s doesn't).

/// Ports `ColorCircleVisualizer` — wedge geometry (`center`, `point(angle(i-1))`, `point(angle(i))`)
/// is purely positional: `angle(i)` depends only on `i`, never on `values[i]`. Changing a value only
/// ever recolors that ONE wedge, so `slots(forIndex:)` stays the default identity mapping — unlike
/// its two siblings below.
struct ColorCircleMetalLayout: MetalTriangleLayout {
  private static func angle(_ index: Int, count: Int) -> Double {
    .pi * (2.0 * Double(index) / Double(count) - 0.5)
  }

  private static func point(atAngle theta: Double, center: SIMD2<Double>, radius: Double) -> SIMD2<
    Double
  > {
    SIMD2(center.x + radius * cos(theta), center.y + radius * sin(theta))
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalTriangleInstance {
    let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
    let radius = min(canvasSize.width, canvasSize.height) / 2.75
    let start = Self.point(
      atAngle: Self.angle(index - 1, count: count), center: center, radius: radius)
    let end = Self.point(atAngle: Self.angle(index, count: count), center: center, radius: radius)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      p0: SIMD2(Float(center.x), Float(center.y)),
      p1: SIMD2(Float(start.x), Float(start.y)),
      p2: SIMD2(Float(end.x), Float(end.y)),
      colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `DisparityCircleVisualizer` — each point's RADIUS is value-dependent (`disp`), and wedge
/// `index`'s triangle uses `point(index - 1)` and `point(index)`. Changing `values[index]` moves
/// point `index`, which both wedge `index` (as its own endpoint) and wedge `index + 1` (as ITS
/// start point) depend on — `slots(forIndex:)` must repaint both, or wedge `index + 1` would keep
/// showing a stale corner until some unrelated full `reset`.
struct DisparityCircleMetalLayout: MetalTriangleLayout {
  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [index, (index + 1) % count]
  }

  private static func disparity(value: Int, index: Int, count: Int) -> Double {
    (1 + cos(.pi * Double(value - index) / (Double(count) * 0.5))) * 0.5
  }

  private static func angle(_ index: Int, count: Int) -> Double {
    .pi * (2.0 * Double(index) / Double(count) - 0.5)
  }

  private static func point(
    forIndex index: Int, values: [Int], center: SIMD2<Double>, radius: Double, count: Int
  ) -> SIMD2<Double> {
    let disp = Self.disparity(value: values[index], index: index, count: count)
    let theta = Self.angle(index, count: count)
    return SIMD2(center.x + disp * radius * cos(theta), center.y + disp * radius * sin(theta))
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalTriangleInstance {
    let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
    let radius = min(canvasSize.width, canvasSize.height) / 2.5
    let previousIndex = (index - 1 + count) % count
    let start = Self.point(
      forIndex: previousIndex, values: values, center: center, radius: radius, count: count)
    let end = Self.point(
      forIndex: index, values: values, center: center, radius: radius, count: count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      p0: SIMD2(Float(center.x), Float(center.y)),
      p1: SIMD2(Float(start.x), Float(start.y)),
      p2: SIMD2(Float(end.x), Float(end.y)),
      colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `SpiralVisualizer` — same wedge-neighbor dependency as `DisparityCircleMetalLayout`
/// (radius modulated by `mult`, a different value-to-radius curve), same `slots(forIndex:)` fix.
struct SpiralMetalLayout: MetalTriangleLayout {
  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [index, (index + 1) % count]
  }

  private static func angle(_ index: Int, count: Int) -> Double {
    .pi * (2.0 * Double(index) / Double(count) - 0.5)
  }

  private static func point(
    forIndex index: Int, values: [Int], valueRange: ClosedRange<Int>, center: SIMD2<Double>,
    radius: Double, count: Int
  ) -> SIMD2<Double> {
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let mult = 1 - (1 - normalized) * (1 - normalized)
    let theta = Self.angle(index, count: count)
    return SIMD2(center.x + mult * radius * cos(theta), center.y + mult * radius * sin(theta))
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalTriangleInstance {
    let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
    let radius = min(canvasSize.width, canvasSize.height) / 2.5
    let previousIndex = (index - 1 + count) % count
    let start = Self.point(
      forIndex: previousIndex, values: values, valueRange: valueRange, center: center,
      radius: radius, count: count)
    let end = Self.point(
      forIndex: index, values: values, valueRange: valueRange, center: center, radius: radius,
      count: count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      p0: SIMD2(Float(center.x), Float(center.y)),
      p1: SIMD2(Float(start.x), Float(start.y)),
      p2: SIMD2(Float(end.x), Float(end.y)),
      colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}
