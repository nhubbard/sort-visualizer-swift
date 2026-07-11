import SortEngineKit
import SwiftUI
import VisualizationKit

/// Replaces the hardcoded `BarLayout`/`Bar` pair: one `Canvas` that asks whichever `Visualizer` is
/// currently selected (§2A) to turn the replay's current frame into draw commands. Switching
/// styles mid-run is just changing which `Visualizer` this reads — `ReplayEngine`/`SortSession`
/// are completely unaware a style even exists.
struct VisualizationCanvas: View {
    let replay: ReplayEngine
    let visualizer: any Visualizer

    var body: some View {
        Canvas { graphicsContext, size in
            let values = replay.frame.map(\.value)
            let markers = Dictionary(
                uniqueKeysWithValues: replay.frame.enumerated().map { ($0.offset, $0.element.markers) }
            )
            let context = VisualizationContext(
                values: values,
                valueRange: Self.valueRange(for: values),
                markers: markers,
                auxArrays: replay.auxArrays,
                canvasSize: size,
                colorSeed: replay.header.visualSeed
            )
            for command in visualizer.draw(context) {
                graphicsContext.draw(command)
            }
        }
    }

    private static func valueRange(for values: [Int]) -> ClosedRange<Int> {
        guard let minValue = values.min(), let maxValue = values.max(), minValue < maxValue else {
            return 0...1
        }
        return minValue...maxValue
    }
}

private extension GraphicsContext {
    func draw(_ command: DrawCommand) {
        switch command {
        case let .rect(x, y, width, height, color):
            fill(Path(CGRect(x: x, y: y, width: width, height: height)), with: .color(color.swiftUIColor))
        case let .ellipse(x, y, width, height, color):
            fill(Path(ellipseIn: CGRect(x: x, y: y, width: width, height: height)), with: .color(color.swiftUIColor))
        case let .line(x1, y1, x2, y2, color, lineWidth):
            var path = Path()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            stroke(path, with: .color(color.swiftUIColor), lineWidth: lineWidth)
        case let .polygon(points, color):
            guard let first = points.first else { return }
            var path = Path()
            path.move(to: CGPoint(x: first.x, y: first.y))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            path.closeSubpath()
            fill(path, with: .color(color.swiftUIColor))
        case let .text(x, y, string, color):
            draw(Text(string).foregroundColor(color.swiftUIColor), at: CGPoint(x: x, y: y))
        }
    }
}

private extension RGBAColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
