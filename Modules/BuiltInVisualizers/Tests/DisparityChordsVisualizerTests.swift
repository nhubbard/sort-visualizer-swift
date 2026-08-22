import CoreGraphics
import SortEngineKit
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct DisparityChordsVisualizerTests {
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
  func emitsOneLinePerValue() {
    let context = makeContext(values: [1, 2, 3, 4])
    let commands = DisparityChordsVisualizer().draw(context)

    #expect(commands.count == 4)
    for command in commands {
      guard case .line = command else {
        Issue.record("expected .line")
        return
      }
    }
  }

  /// Hand-computed against ArrayV's own `π*(2k/n - 0.5)` angle formula for `n = 4`: index 0 sits
  /// at angle -π/2 (straight up from center), value 1 sits at angle 0 (straight right) — a
  /// concrete endpoint pair, not just "it doesn't crash."
  @Test
  func firstChordConnectsItsAngleToItsValuesAngle() {
    let context = makeContext(values: [1, 2, 3, 4], canvasSize: CGSize(width: 200, height: 200))
    let commands = DisparityChordsVisualizer().draw(context)

    guard case .line(let x1, let y1, let x2, let y2, _, _) = commands[0] else {
      Issue.record("expected .line")
      return
    }
    let centerX = 100.0
    let centerY = 100.0
    let radius = 200.0 / 2.5
    #expect(abs(x1 - centerX) < 0.01, "angle -π/2 should have no x offset from center")
    #expect(abs(y1 - (centerY - radius)) < 0.01, "angle -π/2 points straight up")
    #expect(abs(x2 - (centerX + radius)) < 0.01, "angle 0 points straight right")
    #expect(abs(y2 - centerY) < 0.01, "angle 0 should have no y offset from center")
  }

  @Test
  func colorsReflectMarkerState() {
    let context = makeContext(
      values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
    let commands = DisparityChordsVisualizer().draw(context)

    guard case .line(_, _, _, _, let color0, _) = commands[0],
      case .line(_, _, _, _, let color1, _) = commands[1],
      case .line(_, _, _, _, let color2, _) = commands[2]
    else {
      Issue.record("expected .line")
      return
    }
    #expect(color0 != color1)
    #expect(color1 != color2)
    #expect(color0 != color2)
  }

  @Test
  func emptyValuesProducesNoCommands() {
    #expect(DisparityChordsVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
  }

  @Test
  func degenerateCanvasSizeProducesNoCommands() {
    #expect(
      DisparityChordsVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
  }
}
