import CoreGraphics
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct RainbowVisualizerTests {
  private func makeContext(
    values: [Int],
    valueRange: ClosedRange<Int>? = nil,
    canvasSize: CGSize = CGSize(width: 100, height: 50)
  ) -> VisualizationContext {
    VisualizationContext(
      values: values,
      valueRange: valueRange ?? (values.min() ?? 0)...(values.max() ?? 1),
      markers: [:],
      auxArrays: [:],
      canvasSize: canvasSize,
      colorSeed: 0
    )
  }

  @Test
  func emitsOneRectPerValueSizedByRange() {
    let context = makeContext(
      values: [1, 2, 4], valueRange: 1...4, canvasSize: CGSize(width: 90, height: 40))
    let commands = RainbowVisualizer().draw(context)

    #expect(commands.count == 3)
    guard case .rect(_, let y0, let w0, let h0, _) = commands[0],
      case .rect(_, _, _, _, _) = commands[1],
      case .rect(_, let y2, _, let h2, _) = commands[2]
    else {
      Issue.record("expected all commands to be .rect")
      return
    }
    #expect(w0 == 30)
    #expect(h0 == 0)
    #expect(y0 == 40)
    #expect(h2 == 40)
    #expect(y2 == 0)
  }

  @Test
  func colorComesFromValuePositionNotMarkers() {
    // Two bars with identical values but this visualizer never reads markers at all, so an
    // (unused) marker parameter existing in the context must not affect the result.
    let plainContext = makeContext(values: [1, 4], valueRange: 1...4)
    let markedContext = VisualizationContext(
      values: [1, 4],
      valueRange: 1...4,
      markers: [0: [1], 1: [2]],
      auxArrays: [:],
      canvasSize: CGSize(width: 100, height: 50),
      colorSeed: 0
    )

    #expect(RainbowVisualizer().draw(plainContext) == RainbowVisualizer().draw(markedContext))
  }

  @Test
  func lowAndHighValuesGetDifferentHues() {
    let context = makeContext(values: [1, 4], valueRange: 1...4)
    let commands = RainbowVisualizer().draw(context)

    guard case .rect(_, _, _, _, let colorLow) = commands[0],
      case .rect(_, _, _, _, let colorHigh) = commands[1]
    else {
      Issue.record("expected .rect")
      return
    }
    #expect(colorLow != colorHigh)
  }

  @Test
  func emptyValuesProducesNoCommands() {
    let context = makeContext(values: [], valueRange: 0...1)
    #expect(RainbowVisualizer().draw(context).isEmpty)
  }
}
