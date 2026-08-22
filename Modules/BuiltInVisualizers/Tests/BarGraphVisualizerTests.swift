import CoreGraphics
import SortEngineKit
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct BarGraphVisualizerTests {
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
  func emitsOneRectPerValueSizedByRange() {
    let context = makeContext(
      values: [1, 2, 4], valueRange: 1...4, canvasSize: CGSize(width: 90, height: 40))
    let commands = BarGraphVisualizer().draw(context)

    #expect(commands.count == 3)
    guard case .rect(let x0, let y0, let w0, let h0, _) = commands[0],
      case .rect(let x1, _, let w1, let h1, _) = commands[1],
      case .rect(let x2, let y2, let w2, let h2, _) = commands[2]
    else {
      Issue.record("expected all commands to be .rect")
      return
    }

    // width = canvasWidth / count
    #expect(w0 == 30)
    #expect(w1 == 30)
    #expect(w2 == 30)
    // x positions tile left-to-right with no gaps
    #expect(x0 == 0)
    #expect(x1 == 30)
    #expect(x2 == 60)
    // value 1 of range 1...4 -> normalized 0 -> zero height, bottom-anchored
    #expect(h0 == 0)
    #expect(y0 == 40)
    // value 4 of range 1...4 -> normalized 1 -> full height, y = 0
    #expect(h2 == 40)
    #expect(y2 == 0)
    // value 2 of range 1...4 -> normalized 1/3
    #expect(abs(h1 - 40.0 / 3.0) < 0.0001)
  }

  @Test
  func colorsReflectMarkerState() {
    let context = makeContext(
      values: [5, 5, 5],
      markers: [0: [Marker.primary], 1: [Marker.secondary]]
    )
    let commands = BarGraphVisualizer().draw(context)

    guard case .rect(_, _, _, _, let color0) = commands[0],
      case .rect(_, _, _, _, let color1) = commands[1],
      case .rect(_, _, _, _, let color2) = commands[2]
    else {
      Issue.record("expected all commands to be .rect")
      return
    }

    #expect(color0 != color1)
    #expect(color1 != color2)
    #expect(color0 != color2)
  }

  @Test
  func emptyValuesProducesNoCommands() {
    let context = makeContext(values: [], valueRange: 0...1)
    #expect(BarGraphVisualizer().draw(context).isEmpty)
  }

  @Test
  func degenerateCanvasSizeProducesNoCommands() {
    let context = makeContext(values: [1, 2, 3], canvasSize: .zero)
    #expect(BarGraphVisualizer().draw(context).isEmpty)
  }

  @Test
  func allEqualValuesFillCompletelyWithoutDivideByZero() {
    let context = makeContext(
      values: [7, 7, 7], valueRange: 7...7, canvasSize: CGSize(width: 30, height: 20))
    let commands = BarGraphVisualizer().draw(context)

    for command in commands {
      guard case .rect(_, let y, _, let height, _) = command else {
        Issue.record("expected .rect")
        continue
      }
      #expect(height == 20)
      #expect(y == 0)
    }
  }
}
