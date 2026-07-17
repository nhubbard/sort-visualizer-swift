import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `ColorCircle` (circles family): the array isn't a row of bars at all,
/// it's a full circle sliced into `n` equal-angle pie wedges — one wedge per position, each colored
/// by that position's value via `RGBAColor.hueRamp`. Marked positions swap in a highlight color
/// instead of participating in the hue ramp.
public struct ColorCircleVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "colorcircle")
  public let metadata = VisualizerMetadata(
    displayName: "Color Circle",
    supportsAuxArrays: false,
    iconName: "circle.hexagongrid.fill"
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
    let radius = min(context.canvasSize.width, context.canvasSize.height) / 2.75

    func angle(_ index: Int) -> Double {
      .pi * (2.0 * Double(index) / Double(count) - 0.5)
    }

    func point(atAngle theta: Double) -> SIMD2<Double> {
      SIMD2<Double>(center.x + radius * cos(theta), center.y + radius * sin(theta))
    }

    return context.values.enumerated().map { index, value in
      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let start = point(atAngle: angle(index - 1))
      let end = point(atAngle: angle(index))
      return .polygon(
        points: [center, start, end],
        color: color(forIndex: index, normalized: normalized, in: context)
      )
    }
  }

  private func color(forIndex index: Int, normalized: Double, in context: VisualizationContext)
    -> RGBAColor
  {
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
