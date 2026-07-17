import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `WaveDots` — dots mode only (its "lines mode" toggle doesn't map to
/// anything in our `Visualizer` protocol, so it's dropped). One dot per column, laid out
/// left-to-right like `ScatterPlotVisualizer`, but its vertical position is driven by the
/// position's *value* through a sine wave rather than by height — as the array sorts, the dots
/// settle into a smooth ascending arc; while unsorted, they scatter vertically.
public struct WaveDotsVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "wavedots")
  public let metadata = VisualizerMetadata(
    displayName: "Wave Dots",
    supportsAuxArrays: false,
    iconName: "water.waves"
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
    let verticalCenter = context.canvasSize.height / 2
    // Sized so the wave's extremes (sin = ±1) land exactly at the canvas edge minus the dot's
    // own radius, rather than a fixed fraction of the height that only happens to leave enough
    // margin at typical canvas sizes.
    let amplitude = context.canvasSize.height / 2 - radius

    return context.values.enumerated().map { index, value in
      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let centerX = Double(index) * columnWidth + columnWidth / 2
      let centerY = verticalCenter + amplitude * sin(2 * Double.pi * normalized)
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
