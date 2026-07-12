import Foundation
import SortEngineKit
import VisualizationKit

/// Port of ArrayV's `SineWave` (bars family): each array position still draws as a short
/// horizontal bar, but unlike `BarGraphVisualizer` the bar's *height* never encodes the value —
/// instead the bar's vertical position rides a sine wave whose phase is driven by the value's
/// position within `valueRange`. Marked positions draw in a highlight color instead of the usual
/// `hueRamp`, same convention as `ScatterPlotVisualizer`.
public struct SineWaveVisualizer: Visualizer {
    public let id = VisualizerID(rawValue: "sinewave")
    public let metadata = VisualizerMetadata(
        displayName: "Sine Wave",
        supportsAuxArrays: false,
        iconName: "waveform.path"
    )

    private static let barThickness: Double = 5
    private static let amplitudeFraction: Double = 0.4
    private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
    private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

    public init() {}

    public func draw(_ context: VisualizationContext) -> [DrawCommand] {
        guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0 else {
            return []
        }

        let count = context.values.count
        let columnWidth = context.canvasSize.width / Double(count)
        let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
        let centerY = context.canvasSize.height / 2
        let amplitude = context.canvasSize.height * Self.amplitudeFraction

        return context.values.enumerated().map { index, value in
            let normalized = spanLength > 0
                ? Double(value - context.valueRange.lowerBound) / spanLength
                : 1.0
            let y = centerY - amplitude * sin(2 * Double.pi * normalized)
            return .rect(
                x: Double(index) * columnWidth,
                y: y - Self.barThickness / 2,
                width: columnWidth,
                height: Self.barThickness,
                color: color(forIndex: index, normalized: normalized, in: context)
            )
        }
    }

    private func color(forIndex index: Int, normalized: Double, in context: VisualizationContext) -> RGBAColor {
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
