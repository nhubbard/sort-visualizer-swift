import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct DisparityDotsVisualizerTests {
    private func makeContext(
        values: [Int],
        valueRange: ClosedRange<Int>? = nil,
        markers: [Int: Set<Int>] = [:],
        canvasSize: CGSize = CGSize(width: 100, height: 100)
    ) -> VisualizationContext {
        VisualizationContext(
            values: values,
            valueRange: valueRange ?? (values.min() ?? 0)...(values.max() ?? 1),
            markers: markers,
            auxArrays: [:],
            canvasSize: canvasSize,
            colorSeed: 0
        )
    }

    @Test
    func emitsOneEllipsePerValue() {
        let context = makeContext(values: [1, 2, 3, 4])
        let commands = DisparityDotsVisualizer().draw(context)

        #expect(commands.count == 4)
        for command in commands {
            guard case .ellipse = command else {
                Issue.record("expected .ellipse")
                return
            }
        }
    }

    @Test
    func dotsAreFixedSizeRegardlessOfDisparity() {
        let context = makeContext(values: [4, 3, 2, 1])
        let commands = DisparityDotsVisualizer().draw(context)

        guard case let .ellipse(_, _, w0, h0, _) = commands[0],
              case let .ellipse(_, _, w1, h1, _) = commands[1]
        else {
            Issue.record("expected .ellipse")
            return
        }
        #expect(w0 == w1)
        #expect(h0 == h1)
    }

    /// Same underlying formula `DisparityCircleVisualizerTests`' hand-computed case checks — a
    /// sorted `1...n` array has a constant `value - index`, so every dot should sit the same
    /// distance from center.
    @Test
    func sortedArrayProducesUniformRadiusDots() {
        let context = makeContext(values: [1, 2, 3, 4])
        let commands = DisparityDotsVisualizer().draw(context)
        let center = SIMD2<Double>(50, 50)

        let radii = commands.compactMap { command -> Double? in
            guard case let .ellipse(x, y, w, h, _) = command else { return nil }
            let dotCenter = SIMD2<Double>(x + w / 2, y + h / 2)
            let delta = dotCenter - center
            return (delta.x * delta.x + delta.y * delta.y).squareRoot()
        }
        #expect(radii.count == 4)
        #expect(radii.allSatisfy { abs($0 - radii[0]) < 0.01 })
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = DisparityDotsVisualizer().draw(context)

        guard case let .ellipse(_, _, _, _, color0) = commands[0],
              case let .ellipse(_, _, _, _, color1) = commands[1],
              case let .ellipse(_, _, _, _, color2) = commands[2]
        else {
            Issue.record("expected .ellipse")
            return
        }
        #expect(color0 != color1)
        #expect(color1 != color2)
        #expect(color0 != color2)
    }

    @Test
    func emptyValuesProducesNoCommands() {
        #expect(DisparityDotsVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(DisparityDotsVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
