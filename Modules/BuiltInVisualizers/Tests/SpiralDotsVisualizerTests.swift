import CoreGraphics
import Foundation
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct SpiralDotsVisualizerTests {
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
    func emitsOneEllipsePerValueNotOneWedgePerValue() {
        let context = makeContext(values: [1, 2, 3])
        let commands = SpiralDotsVisualizer().draw(context)

        #expect(commands.count == 3)
        for command in commands {
            guard case .ellipse = command else {
                Issue.record("expected .ellipse, proving this isn't secretly wedge-shaped")
                return
            }
        }
    }

    @Test
    func dotsAreFixedSizeRegardlessOfValue() {
        let context = makeContext(values: [1, 4], valueRange: 1...4)
        let commands = SpiralDotsVisualizer().draw(context)

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
    func lowValueDotSitsCloserToCenterThanHighValueDot() {
        let canvasSize = CGSize(width: 100, height: 50)
        let context = makeContext(values: [1, 4], valueRange: 1...4, canvasSize: canvasSize)
        let commands = SpiralDotsVisualizer().draw(context)

        guard case let .ellipse(x0, y0, w0, h0, _) = commands[0],
              case let .ellipse(x1, y1, w1, h1, _) = commands[1]
        else {
            Issue.record("expected .ellipse")
            return
        }

        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let distanceLow = hypot((x0 + w0 / 2) - centerX, (y0 + h0 / 2) - centerY)
        let distanceHigh = hypot((x1 + w1 / 2) - centerX, (y1 + h1 / 2) - centerY)

        // Radius scales linearly with value, unlike Spiral's squared falloff, so the lowest value
        // should sit nearest to center and the highest value nearest to the outer radius.
        #expect(distanceLow < distanceHigh)
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = SpiralDotsVisualizer().draw(context)

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
        #expect(SpiralDotsVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(SpiralDotsVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}
