import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct PixelMeshVisualizerTests {
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
    func emitsOneRectPerCellForAPerfectSquareCount() {
        // 9 is already a perfect square, so the grid has exactly one cell per value.
        let context = makeContext(values: Array(0..<9))
        let commands = PixelMeshVisualizer().draw(context)

        #expect(commands.count == 9)
        for command in commands {
            guard case .rect = command else {
                Issue.record("expected .rect, proving this is grid-shaped rather than bar-shaped")
                return
            }
        }
    }

    @Test
    func gridCellCountRoundsUpToTheNextPerfectSquare() {
        // ceil(sqrt(10)) == 4, so the grid is 4x4 == 16 cells even though there are only 10 values.
        let context = makeContext(values: Array(0..<10))
        let commands = PixelMeshVisualizer().draw(context)

        #expect(commands.count == 16)
    }

    @Test
    func cellsAreSizedByGridDimensionNotByValueCount() {
        let context = makeContext(values: Array(0..<10), canvasSize: CGSize(width: 100, height: 80))
        let commands = PixelMeshVisualizer().draw(context)

        // sqrt(ceil) == 4, so each cell should be canvas/4 in both dimensions.
        for command in commands {
            guard case let .rect(_, _, width, height, _) = command else {
                Issue.record("expected .rect")
                return
            }
            #expect(width == 25)
            #expect(height == 20)
        }
    }

    @Test
    func colorReflectsValueViaHueRamp() {
        let context = makeContext(values: Array(0...8), valueRange: 0...8)
        let commands = PixelMeshVisualizer().draw(context)

        guard case let .rect(_, _, _, _, lowColor) = commands[0],
              case let .rect(_, _, _, _, highColor) = commands[8]
        else {
            Issue.record("expected .rect")
            return
        }
        #expect(lowColor == RGBAColor.hueRamp(0))
        #expect(highColor == RGBAColor.hueRamp(1))
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: Array(0..<9), valueRange: 0...8, markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = PixelMeshVisualizer().draw(context)

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
    func markerLookupUsesUnderlyingArrayIndexNotCellIndex() {
        // n=3 -> sqrt=2 -> 4 cells, scale=0.75, so cellIndex->idx is [0, 0, 1, 2]: cells 0 and 1
        // both resample original index 0, so marking index 0 should color both of those cells,
        // not just the one whose cellIndex happens to equal 0.
        let context = makeContext(values: [10, 20, 30], valueRange: 10...30, markers: [0: [Marker.primary]])
        let commands = PixelMeshVisualizer().draw(context)

        #expect(commands.count == 4)
        guard case let .rect(_, _, _, _, color0) = commands[0],
              case let .rect(_, _, _, _, color1) = commands[1],
              case let .rect(_, _, _, _, color2) = commands[2]
        else {
            Issue.record("expected .rect")
            return
        }
        #expect(color0 == RGBAColor(red: 0.95, green: 0.38, blue: 0.38, alpha: 1))
        #expect(color1 == color0)
        #expect(color2 != color0)
    }

    @Test
    func emptyValuesProducesNoCommands() {
        #expect(PixelMeshVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(PixelMeshVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
