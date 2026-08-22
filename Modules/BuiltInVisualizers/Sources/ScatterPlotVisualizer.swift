import SortEngineKit
import VisualizationKit

/// A real layout change, not just a recolored bar graph — one dot per column at its value's
/// height, proving the `Visualizer` abstraction isn't secretly bar-shaped.
public struct ScatterPlotVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "scatterplot")
  public let metadata = VisualizerMetadata(
    displayName: "Scatter Plot",
    supportsAuxArrays: false,
    iconName: "circle.grid.3x3.fill"
  )

  private static let dotDiameter: Double = 6
  private static let defaultColor = RGBAColor(red: 0.82, green: 0.82, blue: 0.86, alpha: 1)
  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let columnWidth = context.canvasSize.width / Double(count)
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
    let radius = Self.dotDiameter / 2

    return context.values.enumerated().map { index, value in
      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let centerX = Double(index) * columnWidth + columnWidth / 2
      // Inset by the dot's own radius so a value at either extreme (0 or 1) centers its dot
      // fully inside the canvas instead of on the literal edge, where half of it would hang
      // off and get clipped.
      let centerY = radius + (context.canvasSize.height - 2 * radius) * (1 - normalized)
      return .ellipse(
        x: centerX - radius,
        y: centerY - radius,
        width: Self.dotDiameter,
        height: Self.dotDiameter,
        color: color(forIndex: index, in: context)
      )
    }
  }

  private func color(forIndex index: Int, in context: VisualizationContext) -> RGBAColor {
    let markers = context.markers[index] ?? []
    if markers.contains(Marker.primary) {
      return Self.primaryColor
    }
    if markers.contains(Marker.secondary) {
      return Self.secondaryColor
    }
    return Self.defaultColor
  }
}
