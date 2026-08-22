import CoreGraphics
import SortEngineKit
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct HoopStackVisualizerTests {
  private func makeContext(
    values: [Int],
    valueRange: ClosedRange<Int>? = nil,
    markers: [Int: Set<Int>] = [:],
    canvasSize: CGSize = CGSize(width: 100, height: 90)
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
    let commands = HoopStackVisualizer().draw(context)

    #expect(commands.count == 3)
    for command in commands {
      guard case .ellipse = command else {
        Issue.record("expected .ellipse, one hoop per position")
        return
      }
    }
  }

  @Test
  func hoopSizeScalesWithValue() {
    // Drawn back-to-front from n-1 down to 0, so commands[0] is the highest index (value 10)
    // and commands[1] is index 0 (value 1).
    let context = makeContext(values: [1, 10], valueRange: 1...10)
    let commands = HoopStackVisualizer().draw(context)

    guard case .ellipse(_, _, let highWidth, let highHeight, _) = commands[0],
      case .ellipse(_, _, let lowWidth, let lowHeight, _) = commands[1]
    else {
      Issue.record("expected .ellipse")
      return
    }
    #expect(highWidth > lowWidth)
    #expect(highHeight > lowHeight)
    // Preserve the wide, flat "hoop viewed edge-on" proportions.
    #expect(highWidth > highHeight)
  }

  @Test
  func colorsReflectMarkerState() {
    let context = makeContext(
      values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
    let commands = HoopStackVisualizer().draw(context)

    guard case .ellipse(_, _, _, _, let unmarkedColor) = commands[0],
      case .ellipse(_, _, _, _, let secondaryColor) = commands[1],
      case .ellipse(_, _, _, _, let primaryColor) = commands[2]
    else {
      Issue.record("expected .ellipse")
      return
    }
    #expect(primaryColor != unmarkedColor)
    #expect(secondaryColor != unmarkedColor)
    #expect(primaryColor != secondaryColor)
  }

  @Test
  func emptyValuesProducesNoCommands() {
    #expect(HoopStackVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
  }

  @Test
  func degenerateCanvasSizeProducesNoCommands() {
    #expect(HoopStackVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
  }
}
