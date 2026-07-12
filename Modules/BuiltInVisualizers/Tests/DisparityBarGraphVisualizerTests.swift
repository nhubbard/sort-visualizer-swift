import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct DisparityBarGraphVisualizerTests {
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
    func emitsOneRectPerValue() {
        let context = makeContext(values: [1, 2, 3])
        let commands = DisparityBarGraphVisualizer().draw(context)

        #expect(commands.count == 3)
        for command in commands {
            guard case .rect = command else {
                Issue.record("expected .rect")
                return
            }
        }
    }

    /// A sorted `1...n` array has a constant `value - index` (always 1), so every bar's
    /// disparity — and therefore height — should come out identical, unlike a plain bar graph
    /// where a sorted array produces an ascending staircase.
    @Test
    func sortedArrayProducesUniformBarHeights() {
        let context = makeContext(values: [1, 2, 3, 4])
        let commands = DisparityBarGraphVisualizer().draw(context)

        let heights = commands.compactMap { command -> Double? in
            guard case let .rect(_, _, _, height, _) = command else { return nil }
            return height
        }
        #expect(heights.count == 4)
        #expect(heights.allSatisfy { abs($0 - heights[0]) < 0.0001 })
    }

    /// Hand-computed against ArrayV's own `(1 + sin(π * (value - index) / n)) * 0.5` formula for a
    /// reverse-sorted `[4, 3, 2, 1]`: value-index is 4, 2, 0, -2 respectively, landing on the sine
    /// wave's clean points (π, π/2, 0, -π/2) — a concrete check the ported math matches the source,
    /// not just that it doesn't crash.
    @Test
    func disparityMatchesHandComputedValuesForReverseSortedInput() {
        let expected = [0.5, 1.0, 0.5, 0.0]
        for (index, value) in [4, 3, 2, 1].enumerated() {
            let disp = DisparityBarGraphVisualizer.disparity(value: value, index: index, count: 4)
            #expect(abs(disp - expected[index]) < 0.0001, "index \(index): expected \(expected[index]), got \(disp)")
        }
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = DisparityBarGraphVisualizer().draw(context)

        guard case let .rect(_, _, _, _, color0) = commands[0],
              case let .rect(_, _, _, _, color1) = commands[1],
              case let .rect(_, _, _, _, color2) = commands[2]
        else {
            Issue.record("expected .rect")
            return
        }
        #expect(color0 != color1)
        #expect(color1 != color2)
        #expect(color0 != color2)
    }

    @Test
    func emptyValuesProducesNoCommands() {
        #expect(DisparityBarGraphVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(DisparityBarGraphVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
