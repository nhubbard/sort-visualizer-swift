import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct WaveDotsVisualizerTests {
    private func makeContext(
        values: [Int],
        valueRange: ClosedRange<Int>? = nil,
        markers: [Int: Set<Int>] = [:],
        canvasSize: CGSize = CGSize(width: 100, height: 50)
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
        let context = makeContext(values: [1, 2, 3])
        let commands = WaveDotsVisualizer().draw(context)

        #expect(commands.count == 3)
        for command in commands {
            guard case .ellipse = command else {
                Issue.record("expected .ellipse, proving this isn't secretly bar-shaped")
                return
            }
        }
    }

    @Test
    func dotsAreFixedSizeRegardlessOfValue() {
        let context = makeContext(values: [1, 4], valueRange: 1...4)
        let commands = WaveDotsVisualizer().draw(context)

        guard case let .ellipse(_, _, w0, h0, _) = commands[0],
              case let .ellipse(_, _, w1, h1, _) = commands[1]
        else {
            Issue.record("expected .ellipse")
            return
        }
        #expect(w0 == w1)
        #expect(h0 == h1)
    }

    @Test
    func valueAffectsVerticalPosition() {
        // Low and high ends of the range land at different phases of the sine wave, so their
        // y positions should differ — we don't assert the exact curve shape, just that the
        // value (not just the index) drives where the dot sits vertically.
        let context = makeContext(values: [1, 4], valueRange: 1...4, canvasSize: CGSize(width: 100, height: 40))
        let commands = WaveDotsVisualizer().draw(context)

        guard case let .ellipse(_, yLow, _, _, _) = commands[0],
              case let .ellipse(_, yHigh, _, _, _) = commands[1]
        else {
            Issue.record("expected .ellipse")
            return
        }
        #expect(yLow != yHigh)
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = WaveDotsVisualizer().draw(context)

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
        #expect(WaveDotsVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(WaveDotsVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
