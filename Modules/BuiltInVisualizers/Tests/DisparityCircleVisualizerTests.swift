import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct DisparityCircleVisualizerTests {
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
    func emitsOneTriangleWedgePerValue() {
        let context = makeContext(values: [1, 2, 3, 4])
        let commands = DisparityCircleVisualizer().draw(context)

        #expect(commands.count == 4)
        for command in commands {
            guard case let .polygon(points, _) = command else {
                Issue.record("expected .polygon")
                return
            }
            #expect(points.count == 3, "expected a center + previous + current triangle")
        }
    }

    /// Hand-computed against ArrayV's own `(1 + cos(π * (value - index) / (n * 0.5))) * 0.5`
    /// formula for a reverse-sorted `[4, 3, 2, 1]`: value-index is 4, 2, 0, -2, landing on the
    /// cosine wave's clean points (2π, π, 0, -π).
    @Test
    func disparityMatchesHandComputedValuesForReverseSortedInput() {
        let expected = [1.0, 0.0, 1.0, 0.0]
        for (index, value) in [4, 3, 2, 1].enumerated() {
            let disp = DisparityCircleVisualizer.disparity(value: value, index: index, count: 4)
            #expect(abs(disp - expected[index]) < 0.0001, "index \(index): expected \(expected[index]), got \(disp)")
        }
    }

    /// A sorted `1...n` array has a constant `value - index` (always 1), so every wedge point
    /// should sit at the same distance from center.
    @Test
    func sortedArrayProducesUniformRadiusPoints() {
        let context = makeContext(values: [1, 2, 3, 4])
        let commands = DisparityCircleVisualizer().draw(context)
        let center = SIMD2<Double>(50, 50)

        let radii = commands.compactMap { command -> Double? in
            guard case let .polygon(points, _) = command, points.count == 3 else { return nil }
            let current = points[2]
            return (current - center).length
        }
        #expect(radii.count == 4)
        #expect(radii.allSatisfy { abs($0 - radii[0]) < 0.01 })
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = DisparityCircleVisualizer().draw(context)

        guard case let .polygon(_, color0) = commands[0],
              case let .polygon(_, color1) = commands[1],
              case let .polygon(_, color2) = commands[2]
        else {
            Issue.record("expected .polygon")
            return
        }
        #expect(color0 != color1)
        #expect(color1 != color2)
        #expect(color0 != color2)
    }

    @Test
    func emptyValuesProducesNoCommands() {
        #expect(DisparityCircleVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(DisparityCircleVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}

private extension SIMD2<Double> {
    var length: Double { (x * x + y * y).squareRoot() }
}
