import CoreGraphics
import Foundation

// One `MetalShapeLayout` per Metal-ported `Visualizer` beyond `BarGraphVisualizer` (which keeps
// its own bespoke `MetalBarRenderer` — see that type's doc comment). Each `instance(atSlot:...)`
// only ever needs to supply a slot's raw underlying value plus color ingredients now — the actual
// on-screen geometry formula (what used to be a direct, line-for-line port of the matching
// `Visualizer.draw(_:)`'s per-index math, computed here in points) has moved to `shape_vertex`
// (`ShapeRenderer.metal`'s `resolveShapeGeometry`, `MetalShapeGeometry.swift`'s Swift-side CPU
// mirror for tests) — see `MetalShapeLayout`'s own doc comment for the full rationale, and each
// layout's `geometryKind` for which shader branch carries its exact formula forward unchanged.

// MARK: - Rect layouts

/// Ports `DisparityBarGraphVisualizer`.
struct DisparityBarGraphMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect
  static let geometryKind: MetalShapeGeometryKind = .disparityBarGraph

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `RainbowVisualizer` — identical layout to `BarGraphVisualizer`, but colored purely from
/// value (no marker override at all, matching the original, which ignores `context.markers`).
struct RainbowMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect
  static let geometryKind: MetalShapeGeometryKind = .rainbow

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(value: Float(value), colorValue: Float(normalized), colorMarker: 0)
  }
}

/// Ports `SineWaveVisualizer`. `barThickness`/`amplitudeFraction` are fixed constants baked
/// directly into `resolveShapeGeometry`'s `.sineWave` branch now (they never varied per-instance
/// or per-frame), not read from here anymore.
struct SineWaveMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect
  static let geometryKind: MetalShapeGeometryKind = .sineWave

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `PixelMeshVisualizer` — the one layout whose instance count and index mapping genuinely
/// differ from `count`: it reshapes the array into a `ceil(sqrt(count))`-side grid, resampling
/// (not padding) any extra cells from earlier indices. `arrayIndex(forSlot:)` matches
/// `PixelMeshVisualizer.draw`'s own `idx = min(count-1, max(0, Int(cellIndex * scale)))` exactly;
/// `slots(forIndex:)` is its analytic inverse (the range of cellIndex whose `floor(cellIndex*scale)`
/// lands on a given index), not a linear scan, so `apply` stays O(touched) instead of O(cellCount).
/// This VALUE-to-cell resampling stays entirely CPU-side, unchanged by the geometry-to-GPU port —
/// only the grid CELL's on-screen placement (a pure function of `slot`/`count`, no value
/// dependency at all) moved to the shader; see `MetalShapeGeometry.swift`'s own doc comment.
struct PixelMeshMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect
  static let geometryKind: MetalShapeGeometryKind = .pixelMesh

  private static func gridSide(for count: Int) -> Int {
    Int(Double(count).squareRoot().rounded(.up))
  }

  static func instanceCount(for count: Int) -> Int {
    let side = gridSide(for: count)
    return side * side
  }

  static func arrayIndex(forSlot slot: Int, count: Int) -> Int {
    let cellCount = instanceCount(for: count)
    guard cellCount > 0, count > 0 else { return 0 }
    let scale = Double(count) / Double(cellCount)
    return min(count - 1, max(0, Int(Double(slot) * scale)))
  }

  static func slots(forIndex index: Int, count: Int) -> [Int] {
    let cellCount = instanceCount(for: count)
    guard cellCount > 0, count > 0 else { return [] }
    let scale = Double(count) / Double(cellCount)
    let lower = max(0, Int((Double(index) / scale).rounded(.up)))
    // The LAST index absorbs every remaining cell through `cellCount`, exactly mirroring
    // `arrayIndex`'s own `min(count - 1, ...)` clamp — without this, floating-point rounding
    // at the boundary could leave a trailing cell unclaimed by any index's `slots`.
    let upperExclusive =
      index == count - 1 ? cellCount : Int((Double(index + 1) / scale).rounded(.up))
    guard lower < upperExclusive else { return [] }
    return Array(lower..<min(cellCount, upperExclusive))
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

// MARK: - Ellipse layouts

/// Ports `ScatterPlotVisualizer`. `dotDiameter` is a fixed constant baked directly into
/// `resolveShapeGeometry`'s `.scatterPlot` branch now.
struct ScatterPlotMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  static let geometryKind: MetalShapeGeometryKind = .scatterPlot
  // Flat, non-hue-ramped default — see `MetalShapeLayout.usesHueRamp`'s own doc comment.
  static let usesHueRamp = false

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    MetalShapeInstance(
      value: Float(values[index]), colorValue: 0,
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `WaveDotsVisualizer`. `dotDiameter` is a fixed constant baked directly into
/// `resolveShapeGeometry`'s `.waveDots` branch now.
struct WaveDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  static let geometryKind: MetalShapeGeometryKind = .waveDots
  // Flat, non-hue-ramped default — see `MetalShapeLayout.usesHueRamp`'s own doc comment.
  static let usesHueRamp = false

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    MetalShapeInstance(
      value: Float(values[index]), colorValue: 0,
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `SpiralDotsVisualizer`. `dotDiameter` is a fixed constant baked directly into
/// `resolveShapeGeometry`'s `.spiralDots` branch now.
struct SpiralDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  static let geometryKind: MetalShapeGeometryKind = .spiralDots

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `DisparityDotsVisualizer` — its `disp` formula matches `DisparityCircleVisualizer.disparity`
/// exactly (that type's own doc comment notes the two share it); duplicated in
/// `resolveShapeGeometry`'s `.disparityDots` branch as a plain expression rather than importing
/// `BuiltInVisualizers` for one static function, same as before the geometry-to-GPU port.
struct DisparityDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  static let geometryKind: MetalShapeGeometryKind = .disparityDots

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}

/// Ports `HoopStackVisualizer` — the other layout with a non-identity slot mapping: the original
/// draws back-to-front (`stride(from: count-1, through: 0, by: -1)`) so index 0 paints last (on
/// top). A single Metal draw call rasterizes/blends instances in ascending `instanceID` order (the
/// same "later submission wins" rule immediate-mode `fill()` calls already rely on for these fully
/// opaque colors), so reversing slot == count-1-index reproduces that ordering exactly. This
/// mapping stays CPU-side, unchanged by the geometry-to-GPU port; `resolveShapeGeometry`'s
/// `.hoopStack` branch reads the already-reversed `arrayIndex` straight from the GPU buffer.
struct HoopStackMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  static let geometryKind: MetalShapeGeometryKind = .hoopStack

  static func arrayIndex(forSlot slot: Int, count: Int) -> Int {
    count - 1 - slot
  }

  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [count - 1 - index]
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalShapeInstance {
    let value = values[index]
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    return MetalShapeInstance(
      value: Float(value), colorValue: Float(normalized),
      colorMarker: MetalShapeColor.markerKind(forIndex: index, in: markers)
    )
  }
}
