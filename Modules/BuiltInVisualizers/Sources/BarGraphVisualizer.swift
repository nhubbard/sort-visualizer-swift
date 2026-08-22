import SortEngineKit
import VisualizationKit

/// The direct port of the app's current, only-ever style — the simplest possible `Visualizer`.
/// Unlike Phase 2's throwaway native `QuickSort`, this one is a permanent `BuiltInVisualizers`
/// conformance: visualizations are native-only for good (§2A.3).
public struct BarGraphVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "bargraph")
  public let metadata = VisualizerMetadata(
    displayName: "Bar Graph",
    supportsAuxArrays: true,
    iconName: "chart.bar.fill"
  )

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
    let barWidth = context.canvasSize.width / Double(count)
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)

    return context.values.enumerated().map { index, value in
      let normalizedHeight =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let height = context.canvasSize.height * normalizedHeight
      return .rect(
        x: Double(index) * barWidth,
        y: context.canvasSize.height - height,
        width: barWidth,
        height: height,
        color: color(forIndex: index, in: context)
      )
    }
  }

  /// `context.markers[index]` empty = default color, contains `Marker.primary`/`.secondary` =
  /// highlighted — what a marker *looks like* is entirely this type's decision (§1.1).
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
