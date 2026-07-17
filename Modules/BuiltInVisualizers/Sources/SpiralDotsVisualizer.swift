import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `SpiralDots`, dots mode only (its "lines mode" toggle doesn't map to
/// anything in our `Visualizer` protocol, so it's dropped). One fixed-size dot per position, laid
/// out around a circle like `ColorCircleVisualizer`'s wedges rather than left-to-right like
/// `ScatterPlotVisualizer` — but unlike `ColorCircleVisualizer`, each position's *distance* from
/// center (not just its angle) is driven by its value, linearly rather than squared.
public struct SpiralDotsVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "spiraldots")
  public let metadata = VisualizerMetadata(
    displayName: "Spiral Dots",
    supportsAuxArrays: false,
    iconName: "circles.hexagongrid"
  )

  private static let dotDiameter: Double = 6
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

    return context.values.enumerated().map { index, value in
      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let angle = Double.pi * (2.0 * Double(index) / Double(count) - 0.5)
      let distance = normalized * radius
      let centerX = center.x + distance * cos(angle)
      let centerY = center.y + distance * sin(angle)
      return .ellipse(
        x: centerX - Self.dotDiameter / 2,
        y: centerY - Self.dotDiameter / 2,
        width: Self.dotDiameter,
        height: Self.dotDiameter,
        color: color(forIndex: index, in: context, normalized: normalized)
      )
    }
  }

  private func color(forIndex index: Int, in context: VisualizationContext, normalized: Double)
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
