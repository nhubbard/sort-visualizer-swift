import CoreGraphics
import Foundation

/// One `MetalTriangleLayout` per wedge-shaped visualizer. Each `instance(atSlot:...)` only ever
/// supplies its slot's raw underlying value + color ingredients now — `triangle_vertex`
/// (`PolygonRenderer.metal`) derives the actual 3 points via `resolveTriangleGeometry`
/// (`AnimatedField.h`/`MetalShapeGeometry.swift`), selected per layout by `geometryKind`. See
/// `MetalTriangleLayout`'s own doc comment for why `DisparityCircleMetalLayout`/`SpiralMetalLayout`
/// override `slots(forIndex:)` (their wedges depend on a NEIGHBOR's value,
/// `ColorCircleMetalLayout`'s doesn't).

/// Ports `ColorCircleVisualizer` — wedge geometry (`center`, `point(angle(i-1))`, `point(angle(i))`)
/// is purely positional: `angle(i)` depends only on `i`, never on `values[i]`. Changing a value only
/// ever recolors that ONE wedge, so `slots(forIndex:)` stays the default identity mapping — unlike
/// its two siblings below.
struct ColorCircleMetalLayout: MetalTriangleLayout {
  static let geometryKind: MetalTriangleGeometryKind = .colorCircle

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalTriangleInstance {
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      value: Float(values[index]),
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
  static let geometryKind: MetalTriangleGeometryKind = .disparityCircle

  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [index, (index + 1) % count]
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalTriangleInstance {
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      value: Float(values[index]),
      colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `SpiralVisualizer` — same wedge-neighbor dependency as `DisparityCircleMetalLayout`
/// (radius modulated by `mult`, a different value-to-radius curve), same `slots(forIndex:)` fix.
struct SpiralMetalLayout: MetalTriangleLayout {
  static let geometryKind: MetalTriangleGeometryKind = .spiral

  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [index, (index + 1) % count]
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalTriangleInstance {
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    return MetalTriangleInstance(
      value: Float(values[index]),
      colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}
