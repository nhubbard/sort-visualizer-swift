import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `DisparityDots` — dots mode only, same call `WaveDotsVisualizer` made
/// for ArrayV's own "lines mode" toggle (see its doc comment): it doesn't map onto anything in our
/// `Visualizer` protocol, so it's dropped. Same `disp`/`angle` math as `DisparityCircleVisualizer`
/// (identical `(1 + cos(π*(value-index)/(n*0.5))) * 0.5` formula and circle layout), but one small
/// dot per index instead of a wedge.
public struct DisparityDotsVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "disparitydots")
  public let metadata = VisualizerMetadata(
    displayName: "Disparity Dots",
    supportsAuxArrays: false,
    iconName: "circle.grid.2x2.fill"
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
    let center = SIMD2<Double>(context.canvasSize.width / 2, context.canvasSize.height / 2)
    // Same `min(w,h)/2.5` inset ArrayV's own `DisparityCircle`/`DisparityDots` share.
    let radius = min(context.canvasSize.width, context.canvasSize.height) / 2.5
    let dotRadius = Self.dotDiameter / 2

    return context.values.enumerated().map { index, value in
      let disp = DisparityCircleVisualizer.disparity(value: value, index: index, count: count)
      let theta = Double.pi * (2.0 * Double(index) / Double(count) - 0.5)
      let centerX = center.x + disp * radius * cos(theta)
      let centerY = center.y + disp * radius * sin(theta)
      return .ellipse(
        x: centerX - dotRadius,
        y: centerY - dotRadius,
        width: Self.dotDiameter,
        height: Self.dotDiameter,
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
