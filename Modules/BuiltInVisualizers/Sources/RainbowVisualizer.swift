import VisualizationKit

/// Trivial — same bar layout as `BarGraphVisualizer`, color purely from value via
/// `RGBAColor.hueRamp` rather than marker state. Exists to prove `Visualizer` is a genuinely
/// swappable axis, independent of `SortSession`/`ReplayEngine`.
public struct RainbowVisualizer: Visualizer {
  public let id = VisualizerID(rawValue: "rainbow")
  public let metadata = VisualizerMetadata(
    displayName: "Rainbow",
    supportsAuxArrays: true,
    iconName: "paintpalette.fill"
  )

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
      let normalized =
        spanLength > 0
        ? Double(value - context.valueRange.lowerBound) / spanLength
        : 1.0
      let height = context.canvasSize.height * normalized
      return .rect(
        x: Double(index) * barWidth,
        y: context.canvasSize.height - height,
        width: barWidth,
        height: height,
        color: .hueRamp(normalized)
      )
    }
  }
}
