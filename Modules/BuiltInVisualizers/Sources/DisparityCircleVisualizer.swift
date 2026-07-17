import Foundation
import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `DisparityCircle` — same wedge-triangle construction as
/// `ColorCircleVisualizer` (`[center, previousPoint, currentPoint]` per index), but each point's
/// distance from center is scaled by `disp`, a 0...1 "how far is this value from home" measure via
/// a cosine wave, instead of always sitting at full radius. A sorted array's wedges all land at the
/// same radius; a scrambled one produces a jagged, uneven ring. Despite `ARCHITECTURE_V2.md`
/// §2A.6's claim, ArrayV's real source (`visuals/circles/DisparityCircle.java`) needs nothing but
/// the current value and index — no `originalIndices` engine feature required.
public struct DisparityCircleVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "disparitycircle")
  public let metadata = VisualizerMetadata(
    displayName: "Disparity Circle",
    supportsAuxArrays: false,
    iconName: "triangle.circle.fill"
  )

  private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
  private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

  public init() {}

  /// ArrayV's `(1 + cos(π * (value - index) / (n * 0.5))) * 0.5` — note the `n * 0.5` divisor,
  /// not the plain `n` `DisparityBarGraphVisualizer` uses; a different wave frequency in the
  /// original source, preserved exactly rather than unified across the two visualizers.
  static func disparity(value: Int, index: Int, count: Int) -> Double {
    (1 + cos(.pi * Double(value - index) / (Double(count) * 0.5))) * 0.5
  }

  /// Same `angle(i) = π*(2i/n - 0.5)` `ColorCircleVisualizer` already uses.
  private static func angle(_ index: Int, count: Int) -> Double {
    .pi * (2.0 * Double(index) / Double(count) - 0.5)
  }

  public func draw(_ context: VisualizationContext) -> [DrawCommand] {
    guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0
    else {
      return []
    }

    let count = context.values.count
    let center = SIMD2<Double>(context.canvasSize.width / 2, context.canvasSize.height / 2)
    // ArrayV's own inset for this style (`min(w,h)/2.5`) — deliberately not the `/2.75`
    // ColorCircleVisualizer uses; a real, if minor, difference in the source worth keeping.
    let radius = min(context.canvasSize.width, context.canvasSize.height) / 2.5

    func point(forIndex index: Int) -> SIMD2<Double> {
      let disp = Self.disparity(value: context.values[index], index: index, count: count)
      let theta = Self.angle(index, count: count)
      return SIMD2<Double>(
        center.x + disp * radius * cos(theta),
        center.y + disp * radius * sin(theta)
      )
    }

    return (0..<count).map { index in
      let previousIndex = (index - 1 + count) % count
      return .polygon(
        points: [center, point(forIndex: previousIndex), point(forIndex: index)],
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
    let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
    let value = context.values[index]
    let normalized =
      spanLength > 0 ? Double(value - context.valueRange.lowerBound) / spanLength : 1.0
    return .hueRamp(normalized)
  }
}
