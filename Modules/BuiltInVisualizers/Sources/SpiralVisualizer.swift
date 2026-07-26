import Foundation
import SortEngineKit
import VisualizationKit

/// Port of ArrayV's `Spiral` (circles family): like `ColorCircleVisualizer`, but each wedge's
/// outer radius is modulated by that position's value — low values pull toward the center, high
/// values reach full radius, blooming into a spiral instead of a plain pie.
///
/// `mult(normalized) = 1 - (1 - normalized)^2` adapts ArrayV's `mult = 1 - (value/arrayLength -
/// 1)^2` to this codebase's `valueRange`-relative `normalized` (0...1) convention. Both satisfy
/// mult(0)=0, mult(1)=1; the polynomial shape differs slightly from the Java original but
/// preserves the same concave ease-out curve.
public struct SpiralVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "spiral")
  public let metadata = VisualizerMetadata(
    displayName: "Spiral",
    supportsAuxArrays: false,
    iconName: "tornado"
  )

  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
    let center = SIMD2<Double>(context.canvasSize.width / 2, context.canvasSize.height / 2)
    let radius = min(context.canvasSize.width, context.canvasSize.height) / 2.5

    func normalized(forValue value: Int) -> Double {
      spanLength > 0 ? Double(value - context.valueRange.lowerBound) / spanLength : 1.0
    }

    func angle(_ index: Int) -> Double {
      .pi * (2.0 * Double(index) / Double(count) - 0.5)
    }

    // Precompute one point per position (rather than re-deriving a neighbor's point on demand)
    // so that slice i's start vertex and slice i+1's end vertex are the exact same point,
    // keeping the spiral's outline continuous. Indexing with `% count` below lets position 0's
    // predecessor wrap to position `count - 1`'s point: `angle(-1)` and `angle(count - 1)` are
    // the same physical angle (they differ by a full 2*pi turn), so the wrap is seamless.
    let points: [SIMD2<Double>] = context.values.enumerated().map { index, value in
      let mult = 1 - (1 - normalized(forValue: value)) * (1 - normalized(forValue: value))
      let theta = angle(index)
      return SIMD2<Double>(
        center.x + mult * radius * cos(theta), center.y + mult * radius * sin(theta))
    }

    return context.values.enumerated().map { index, value in
      let start = points[(index - 1 + count) % count]
      let end = points[index]
      return .polygon(
        points: [center, start, end],
        color: color(forIndex: index, normalized: normalized(forValue: value), in: context)
      )
    }
  }

  private func color(forIndex index: Int, normalized: Double, in context: VisualizationContext)
    -> RGBAColor {
    let markers = context.markers[index] ?? []
    if markers.contains(Marker.primary) {
      return Self.primaryColor
    }
    if markers.contains(Marker.secondary) {
      return Self.secondaryColor
    }
    return .hueRamp(normalized)
  }
}
