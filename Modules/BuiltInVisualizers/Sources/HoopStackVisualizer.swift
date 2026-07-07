import SortEngineKit
import VisualizationKit

/// Ported from ArrayV's `HoopStack` (misc family): every position is drawn as a wide, flat
/// ellipse ("hoop") stacked vertically down the canvas by INDEX, all horizontally centered, with
/// the hoop's SIZE — not its position — encoding that position's VALUE. Bigger value, bigger
/// hoop; a hoop never shrinks to nothing even at the lowest value, so the stack always reads as a
/// full column of rings.
///
/// `DrawCommand.ellipse` is always filled in this codebase (rendered via `GraphicsContext.fill`,
/// same as every other visualizer) — there's no stroked/outline-only primitive like ArrayV's
/// `drawOval`, so unlike the original, overlapping hoops here occlude each other. Drawn back to
/// front from index `n-1` down to `0` (matching ArrayV's own draw order) so earlier indices paint
/// on top of later ones.
public struct HoopStackVisualizer: Visualizer {
    public let id = VisualizerID(rawValue: "hoopstack")
    public let metadata = VisualizerMetadata(
        displayName: "Hoop Stack",
        supportsAuxArrays: false,
        needsOriginalIndices: false,
        iconName: "circle.dashed"
    )

    private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
    private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

    public init() {}

    public func draw(_ context: VisualizationContext) -> [DrawCommand] {
        guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0 else {
            return []
        }

        let count = context.values.count
        let centerX = context.canvasSize.width / 2
        let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)
        // Clamped to half the canvas width too — on a tall, narrow canvas a height-derived radius
        // can otherwise exceed half the width, overflowing the left/right edges.
        let baseRadiusX = min(context.canvasSize.height / 6, context.canvasSize.width / 2)
        let baseRadiusY = context.canvasSize.height / 18

        return stride(from: count - 1, through: 0, by: -1).map { index in
            let value = context.values[index]
            let normalized = spanLength > 0
                ? Double(value - context.valueRange.lowerBound) / spanLength
                : 1.0
            // Inset by `baseRadiusY` (the largest a hoop can be) on both ends, so even the
            // tallest possible hoop at either end of the stack lands fully inside the canvas
            // instead of hanging its top/bottom half off the edge, where `Canvas` clips it.
            let y = count > 1
                ? baseRadiusY + (context.canvasSize.height - 2 * baseRadiusY) * Double(index) / Double(count - 1)
                : context.canvasSize.height / 2
            // Even a zero-normalized value still draws a visible sliver of a hoop.
            let scale = 0.2 + 0.8 * normalized
            let radiusX = scale * baseRadiusX
            let radiusY = scale * baseRadiusY
            return .ellipse(
                x: centerX - radiusX,
                y: y - radiusY,
                width: 2 * radiusX,
                height: 2 * radiusY,
                color: color(forIndex: index, in: context, normalized: normalized)
            )
        }
    }

    private func color(forIndex index: Int, in context: VisualizationContext, normalized: Double) -> RGBAColor {
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
