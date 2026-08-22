import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `DisparityBarGraph` — despite an earlier design draft claiming the
/// Disparity family needs an `originalIndices` engine feature (see
/// Documentation/docs/architecture/content.md), ArrayV's own source computes
/// displacement from just the current value and index (`array[i] - i`), data
/// `VisualizationContext.values` already provides. Bar height is `disp`, a 0...1 "distance from
/// home" measure via a sine wave — sorted arrays render a flat skyline, scrambled ones jagged.
public struct DisparityBarGraphVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "disparitybargraph")
  public let metadata = VisualizerMetadata(
    displayName: "Disparity Bar Graph",
    supportsAuxArrays: false,
    iconName: "chart.bar.xaxis"
  )

  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  /// ArrayV's `(1 + sin(π * (value - index) / n)) * 0.5` — a value sitting exactly `n` positions
  /// away from its index (mod the sine's period) lands back at the same displacement, so this
  /// isn't literally "distance from home," just ArrayV's own chosen wave shape, ported as-is.
  static func disparity(value: Int, index: Int, count: Int) -> Double {
    (1 + sin(.pi * Double(value - index) / Double(count))) * 0.5
  }

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let barWidth = context.canvasSize.width / Double(count)

    return context.values.enumerated().map { index, value in
      let disp = Self.disparity(value: value, index: index, count: count)
      let height = context.canvasSize.height * disp
      return .rect(
        x: Double(index) * barWidth,
        y: context.canvasSize.height - height,
        width: barWidth,
        height: height,
        color: color(forIndex: index, value: value, in: context)
      )
    }
  }

  private func color(forIndex index: Int, value: Int, in context: VisualizationContext) -> RGBAColor {
    let markers = context.markers[index] ?? []
    if markers.contains(Marker.primary) {
      return Self.primaryColor
    }
    if markers.contains(Marker.secondary) {
      return Self.secondaryColor
    }
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
    let normalized =
      spanLength > 0 ? Double(value - context.valueRange.lowerBound) / spanLength : 1.0
    return .hueRamp(normalized)
  }
}
