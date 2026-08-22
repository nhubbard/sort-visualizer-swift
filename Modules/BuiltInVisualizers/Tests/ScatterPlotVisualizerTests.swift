import CoreGraphics
import SortEngineKit
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct ScatterPlotVisualizerTests {
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
  func emitsOneEllipsePerValueNotOneRectPerValue() {
    let context = makeContext(values: [1, 2, 3])
    let commands = ScatterPlotVisualizer().draw(context)

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
    let commands = ScatterPlotVisualizer().draw(context)

    guard case .ellipse(_, _, let w0, let h0, _) = commands[0],
      case .ellipse(_, _, let w1, let h1, _) = commands[1]
    else {
      Issue.record("expected .ellipse")
      return
    }
    #expect(w0 == w1)
    #expect(h0 == h1)
  }

  @Test
  func lowValueDotSitsBelowHighValueDot() {
    let context = makeContext(
      values: [1, 4], valueRange: 1...4, canvasSize: CGSize(width: 100, height: 40))
    let commands = ScatterPlotVisualizer().draw(context)

    guard case .ellipse(_, let yLow, _, _, _) = commands[0],
      case .ellipse(_, let yHigh, _, _, _) = commands[1]
    else {
      Issue.record("expected .ellipse")
      return
    }
    // Canvas y grows downward, so the lower value's dot should have a larger y (visually lower).
    #expect(yLow > yHigh)
  }

  @Test
  func colorsReflectMarkerState() {
    let context = makeContext(
      values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
    let commands = ScatterPlotVisualizer().draw(context)

    guard case .ellipse(_, _, _, _, let color0) = commands[0],
      case .ellipse(_, _, _, _, let color1) = commands[1],
      case .ellipse(_, _, _, _, let color2) = commands[2]
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
    #expect(ScatterPlotVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
  }

  @Test
  func degenerateCanvasSizeProducesNoCommands() {
    #expect(ScatterPlotVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
  }
}
