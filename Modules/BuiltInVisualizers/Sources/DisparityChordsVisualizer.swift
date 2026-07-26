import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `DisparityChords` — unlike its siblings, no wave/disp math: one line
/// per index, from that index's own point on the circle (angle from its *position*) to a second
/// point at the angle corresponding to its *value*. A sorted array draws short chords to near
/// neighbors; a scrambled one draws long chords crossing the circle. Confirms (see
/// `DisparityBarGraphVisualizer`) that the whole Disparity family ports cleanly with no extra
/// state, despite `ARCHITECTURE_V2.md`'s original claim otherwise.
public struct DisparityChordsVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "disparitychords")
  public let metadata = VisualizerMetadata(
    displayName: "Disparity Chords",
    supportsAuxArrays: false,
    iconName: "link.circle.fill"
  )

  private static let lineWidth: Double = 1
  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  /// Same `angle(k) = π*(2k/n - 0.5)` `ColorCircleVisualizer`/`DisparityCircleVisualizer` use,
  /// generalized to a `Double` input since ArrayV plugs a raw *value* into this formula for the
  /// chord's far endpoint, not just an index.
  static func angle(_ position: Double, count: Int) -> Double {
    .pi * (2.0 * position / Double(count) - 0.5)
  }

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let centerX = context.canvasSize.width / 2
    let centerY = context.canvasSize.height / 2
    let radius = min(context.canvasSize.width, context.canvasSize.height) / 2.5

    return context.values.enumerated().map { index, value in
      let fromAngle = Self.angle(Double(index), count: count)
      let toAngle = Self.angle(Double(value), count: count)
      return .line(
        x1: centerX + radius * cos(fromAngle),
        y1: centerY + radius * sin(fromAngle),
        x2: centerX + radius * cos(toAngle),
        y2: centerY + radius * sin(toAngle),
        color: color(forIndex: index, value: value, in: context),
        lineWidth: Self.lineWidth
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
