import CoreGraphics
import SortEngineKit
import Testing
@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct SpiralVisualizerTests {
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
    func emitsOnePolygonPerValue() {
        let context = makeContext(values: [1, 2, 3, 4, 5])
        let commands = SpiralVisualizer().draw(context)

        #expect(commands.count == 5)
        for command in commands {
            guard case .polygon = command else {
                Issue.record("expected .polygon, proving this is pie-slice-shaped, not bar-shaped")
                return
            }
        }
    }

    @Test
    func everySliceIsATriangleAnchoredAtTheCenter() {
        let context = makeContext(values: [1, 2, 3], canvasSize: CGSize(width: 100, height: 60))
        let commands = SpiralVisualizer().draw(context)
        let expectedCenter = SIMD2<Double>(50, 30)

        for command in commands {
            guard case let .polygon(points, _) = command else {
                Issue.record("expected .polygon")
                return
            }
            #expect(points.count == 3)
            #expect(points[0] == expectedCenter)
        }
    }

    @Test
    func lowValuePointSitsCloserToCenterThanHighValuePoint() {
        let canvasSize = CGSize(width: 100, height: 60)
        let context = makeContext(values: [1, 4], valueRange: 1...4, canvasSize: canvasSize)
        let commands = SpiralVisualizer().draw(context)
        let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)

        guard case let .polygon(pointsLow, _) = commands[0],
              case let .polygon(pointsHigh, _) = commands[1]
        else {
            Issue.record("expected .polygon")
            return
        }
        // Each slice's own outer vertex (its "end" point) is the last point in the triangle.
        let distanceLow = (pointsLow[2] - center).magnitude()
        let distanceHigh = (pointsHigh[2] - center).magnitude()
        #expect(distanceLow < distanceHigh)
    }

    @Test
    func fullRadiusValueReachesTheOuterRadiusExactly() {
        let canvasSize = CGSize(width: 100, height: 60)
        let context = makeContext(values: [1, 4], valueRange: 1...4, canvasSize: canvasSize)
        let commands = SpiralVisualizer().draw(context)
        let center = SIMD2<Double>(canvasSize.width / 2, canvasSize.height / 2)
        let expectedRadius = min(canvasSize.width, canvasSize.height) / 2.5

        guard case let .polygon(pointsLow, _) = commands[0],
              case let .polygon(pointsHigh, _) = commands[1]
        else {
            Issue.record("expected .polygon")
            return
        }
        // value == valueRange.lowerBound -> normalized 0 -> mult 0 -> collapses onto the center.
        #expect((pointsLow[2] - center).magnitude() < 0.0001)
        // value == valueRange.upperBound -> normalized 1 -> mult 1 -> reaches the full radius.
        #expect(abs((pointsHigh[2] - center).magnitude() - expectedRadius) < 0.0001)
    }

    @Test
    func colorsReflectMarkerState() {
        let context = makeContext(values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
        let commands = SpiralVisualizer().draw(context)

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
        #expect(SpiralVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
    }

    @Test
    func degenerateCanvasSizeProducesNoCommands() {
        #expect(SpiralVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
    }
}

private extension SIMD2<Double> {
    func magnitude() -> Double {
        (x * x + y * y).squareRoot()
    }
}
