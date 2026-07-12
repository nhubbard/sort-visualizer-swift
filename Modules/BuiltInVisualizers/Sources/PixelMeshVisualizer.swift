import SortEngineKit
import VisualizationKit

/// Direct port of ArrayV's `PixelMesh` (misc family): reshapes the 1-D array into a roughly-square
/// 2-D grid of colored cells instead of a single row of bars. When `n` isn't a perfect square, the
/// grid is padded up to `sqrt(n)` rounded up, and the extra cells resample earlier array indices
/// rather than leaving gaps — so multiple grid cells can map to the same underlying index.
public struct PixelMeshVisualizer: Visualizer {
    public let id = VisualizerID(rawValue: "pixelmesh")
    public let metadata = VisualizerMetadata(
        displayName: "Pixel Mesh",
        supportsAuxArrays: false,
        iconName: "square.grid.3x3.fill"
    )

    private static let primaryColor = RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1)
    private static let secondaryColor = RGBAColor(red: 0.38, green: 0.58, blue: 0.95, alpha: 1)

    public init() {}

    public func draw(_ context: VisualizationContext) -> [DrawCommand] {
        guard !context.values.isEmpty, context.canvasSize.width > 0, context.canvasSize.height > 0 else {
            return []
        }

        let count = context.values.count
        let sqrt = Int(Double(count).squareRoot().rounded(.up))
        guard sqrt > 0 else {
            return []
        }
        let cellCount = sqrt * sqrt
        let scale = Double(count) / Double(cellCount)
        let cellWidth = context.canvasSize.width / Double(sqrt)
        let cellHeight = context.canvasSize.height / Double(sqrt)
        let spanLength = Double(context.valueRange.upperBound - context.valueRange.lowerBound)

        return (0..<cellCount).map { cellIndex in
            let idx = min(count - 1, max(0, Int(Double(cellIndex) * scale)))
            let gridX = cellIndex % sqrt
            let gridY = cellIndex / sqrt
            let value = context.values[idx]
            let normalized = spanLength > 0
                ? Double(value - context.valueRange.lowerBound) / spanLength
                : 1.0

            return .rect(
                x: Double(gridX) * cellWidth,
                y: Double(gridY) * cellHeight,
                width: cellWidth,
                height: cellHeight,
                color: color(forIndex: idx, normalized: normalized, in: context)
            )
        }
    }

    private func color(forIndex idx: Int, normalized: Double, in context: VisualizationContext) -> RGBAColor {
        let markers = context.markers[idx] ?? []
        if markers.contains(Marker.primary) {
            return Self.primaryColor
        }
        if markers.contains(Marker.secondary) {
            return Self.secondaryColor
        }
        return .hueRamp(normalized)
    }
}
