import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct SineWaveVisualizerTests {
    private func makeContext(
        values: [Int],
        valueRange: ClosedRange<Int>? = nil,
        markers: [Int: Set<Int>] = [:],
        canvasSize: CGSize = CGSize(width: 100, height: 40)
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
        let commands = SineWaveVisualizer().draw(context)

        #expect(commands.count == 3)
        for command in commands {
            guard case .rect = command else {
                Issue.record("expected .rect")
                return
            }
        }
    }

    @Test
    func barsAreThinTicksNotTallBars() {
        let context = makeContext(values: [1, 4], valueRange: 1...4, canvasSize: CGSize(width: 100, height: 200))
        let commands = SineWaveVisualizer().draw(context)

        guard case let .rect(_, _, _, height, _) = commands[0] else {
            Issue.record("expected .rect")
            return
        }
        // A "thin tick", not a bar that spans a meaningful fraction of the canvas height.
        #expect(height < context.canvasSize.height * 0.5)
    }

    @Test
    func valueAtZeroNormalizedSitsAtVerticalCenter() {
        // value == valueRange.lowerBound -> normalized == 0 -> sin(0) == 0 -> centered.
        let canvasSize = CGSize(width: 100, height: 40)
        let context = makeContext(values: [0], valueRange: 0...4, canvasSize: canvasSize)
        let commands = SineWaveVisualizer().draw(context)

        guard case let .rect(_, y, _, height, _) = commands[0] else {
            Issue.record("expected .rect")
            return
        }
        let barCenterY = y + height / 2
        #expect(abs(barCenterY - canvasSize.height / 2) < 0.0001)
    }

    @Test
    func differentNormalizedValuesProduceDifferentYPositions() {
        // normalized 0 and 0.25 land on different points of the sine curve.
        let context = makeContext(values: [0, 1], valueRange: 0...4, canvasSize: CGSize(width: 100, height: 40))
        let commands = SineWaveVisualizer().draw(context)

        guard case let .rect(_, y0, _, _, _) = commands[0],
              case let .rect(_, y1, _, _, _) = commands[1]
        else {
            Issue.record("expected .rect")
            return
        }
        #expect(y0 != y1)
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = SineWaveVisualizer().draw(context)

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
        #expect(SineWaveVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(SineWaveVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
