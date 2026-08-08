import CoreGraphics
import Foundation

// One `MetalShapeLayout` per Metal-ported `Visualizer` beyond `BarGraphVisualizer` (which keeps
// its own bespoke `MetalBarRenderer` — see that type's doc comment). Each `instance(atSlot:...)`
// is a direct, line-for-line port of the matching `Visualizer.draw(_:)`'s per-index math, just
// returning one `MetalShapeInstance` instead of appending a `DrawCommand` — see
// `MetalShapeLayout`'s own doc comment for why geometry here is in points, and why `arrayIndex`/
// `slots` default to identity except where noted.

// MARK: - Rect layouts

/// Ports `DisparityBarGraphVisualizer`.
struct DisparityBarGraphMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let value = values[index]
    let barWidth = canvasSize.width / Double(count)
    let disp = (1 + sin(.pi * Double(value - index) / Double(count))) * 0.5
    let height = canvasSize.height * disp
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(Double(index) * barWidth), Float(canvasSize.height - height)),
      size: SIMD2(Float(barWidth), Float(height)),
      color: color
    )
  }
}

/// Ports `RainbowVisualizer` — identical layout to `BarGraphVisualizer`, but colored purely from
/// value (no marker override at all, matching the original, which ignores `context.markers`).
struct RainbowMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let barWidth = canvasSize.width / Double(count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let height = canvasSize.height * normalized
    return MetalShapeInstance(
      origin: SIMD2(Float(Double(index) * barWidth), Float(canvasSize.height - height)),
      size: SIMD2(Float(barWidth), Float(height)),
      color: MetalShapeColor.hueRamp(normalized)
    )
  }
}

/// Ports `SineWaveVisualizer`.
struct SineWaveMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect
  private static let barThickness: Double = 5
  private static let amplitudeFraction: Double = 0.4

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let columnWidth = canvasSize.width / Double(count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let centerY = canvasSize.height / 2
    let amplitude = canvasSize.height * Self.amplitudeFraction
    let y = centerY - amplitude * sin(2 * Double.pi * normalized)
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(Double(index) * columnWidth), Float(y - Self.barThickness / 2)),
      size: SIMD2(Float(columnWidth), Float(Self.barThickness)),
      color: color
    )
  }
}

/// Ports `PixelMeshVisualizer` — the one layout whose instance count and index mapping genuinely
/// differ from `count`: it reshapes the array into a `ceil(sqrt(count))`-side grid, resampling
/// (not padding) any extra cells from earlier indices. `arrayIndex(forSlot:)` matches
/// `PixelMeshVisualizer.draw`'s own `idx = min(count-1, max(0, Int(cellIndex * scale)))` exactly;
/// `slots(forIndex:)` is its analytic inverse (the range of cellIndex whose `floor(cellIndex*scale)`
/// lands on a given index), not a linear scan, so `apply` stays O(touched) instead of O(cellCount).
struct PixelMeshMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .rect

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
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let side = gridSide(for: count)
    guard side > 0 else { return MetalShapeInstance(origin: .zero, size: .zero, color: .zero) }
    let cellWidth = canvasSize.width / Double(side)
    let cellHeight = canvasSize.height / Double(side)
    let gridX = slot % side
    let gridY = slot / side
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(Double(gridX) * cellWidth), Float(Double(gridY) * cellHeight)),
      size: SIMD2(Float(cellWidth), Float(cellHeight)),
      color: color
    )
  }
}

// MARK: - Ellipse layouts

/// Ports `ScatterPlotVisualizer`.
struct ScatterPlotMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  private static let dotDiameter: Double = 6

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let columnWidth = canvasSize.width / Double(count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let radius = Self.dotDiameter / 2
    let centerX = Double(index) * columnWidth + columnWidth / 2
    let centerY = radius + (canvasSize.height - 2 * radius) * (1 - normalized)
    let color = MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.neutral
    return MetalShapeInstance(
      origin: SIMD2(Float(centerX - radius), Float(centerY - radius)),
      size: SIMD2(Float(Self.dotDiameter), Float(Self.dotDiameter)),
      color: color
    )
  }
}

/// Ports `WaveDotsVisualizer`.
struct WaveDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  private static let dotDiameter: Double = 6

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let columnWidth = canvasSize.width / Double(count)
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let radius = Self.dotDiameter / 2
    let verticalCenter = canvasSize.height / 2
    let amplitude = canvasSize.height / 2 - radius
    let centerX = Double(index) * columnWidth + columnWidth / 2
    let centerY = verticalCenter + amplitude * sin(2 * Double.pi * normalized)
    let color = MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.neutral
    return MetalShapeInstance(
      origin: SIMD2(Float(centerX - radius), Float(centerY - radius)),
      size: SIMD2(Float(Self.dotDiameter), Float(Self.dotDiameter)),
      color: color
    )
  }
}

/// Ports `SpiralDotsVisualizer`.
struct SpiralDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  private static let dotDiameter: Double = 6

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let normalized = MetalShapeColor.normalized(value: values[index], in: valueRange)
    let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
    let radius = min(canvasSize.width, canvasSize.height) / 2.5
    let angle = Double.pi * (2.0 * Double(index) / Double(count) - 0.5)
    let distance = normalized * radius
    let centerX = center.x + distance * cos(angle)
    let centerY = center.y + distance * sin(angle)
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(centerX - Self.dotDiameter / 2), Float(centerY - Self.dotDiameter / 2)),
      size: SIMD2(Float(Self.dotDiameter), Float(Self.dotDiameter)),
      color: color
    )
  }
}

/// Ports `DisparityDotsVisualizer` — its `disp` formula matches `DisparityCircleVisualizer.disparity`
/// exactly (that type's own doc comment notes the two share it); duplicated here as a plain
/// expression rather than importing `BuiltInVisualizers` for one static function.
struct DisparityDotsMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse
  private static let dotDiameter: Double = 6

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let value = values[index]
    let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
    let radius = min(canvasSize.width, canvasSize.height) / 2.5
    let dotRadius = Self.dotDiameter / 2
    let disp = (1 + cos(.pi * Double(value - index) / (Double(count) * 0.5))) * 0.5
    let theta = Double.pi * (2.0 * Double(index) / Double(count) - 0.5)
    let centerX = center.x + disp * radius * cos(theta)
    let centerY = center.y + disp * radius * sin(theta)
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(centerX - dotRadius), Float(centerY - dotRadius)),
      size: SIMD2(Float(Self.dotDiameter), Float(Self.dotDiameter)),
      color: color
    )
  }
}

/// Ports `HoopStackVisualizer` — the other layout with a non-identity slot mapping: the original
/// draws back-to-front (`stride(from: count-1, through: 0, by: -1)`) so index 0 paints last (on
/// top). A single Metal draw call rasterizes/blends instances in ascending `instanceID` order (the
/// same "later submission wins" rule immediate-mode `fill()` calls already rely on for these fully
/// opaque colors), so reversing slot == count-1-index reproduces that ordering exactly.
struct HoopStackMetalLayout: MetalShapeLayout {
  static let shapeKind: MetalShapeKind = .ellipse

  static func arrayIndex(forSlot slot: Int, count: Int) -> Int {
    count - 1 - slot
  }

  static func slots(forIndex index: Int, count: Int) -> [Int] {
    [count - 1 - index]
  }

  static func instance(
    atSlot slot: Int, arrayIndex index: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance {
    let value = values[index]
    let centerX = canvasSize.width / 2
    let normalized = MetalShapeColor.normalized(value: value, in: valueRange)
    let baseRadiusX = min(canvasSize.height / 6, canvasSize.width / 2)
    let baseRadiusY = canvasSize.height / 18
    let y =
      count > 1
      ? baseRadiusY + (canvasSize.height - 2 * baseRadiusY) * Double(index) / Double(count - 1)
      : canvasSize.height / 2
    let scale = 0.2 + 0.8 * normalized
    let radiusX = scale * baseRadiusX
    let radiusY = scale * baseRadiusY
    let color =
      MetalShapeColor.marker(forIndex: index, in: markers) ?? MetalShapeColor.hueRamp(normalized)
    return MetalShapeInstance(
      origin: SIMD2(Float(centerX - radiusX), Float(y - radiusY)),
      size: SIMD2(Float(2 * radiusX), Float(2 * radiusY)),
      color: color
    )
  }
}
