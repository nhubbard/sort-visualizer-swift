@testable import BuiltInVisualizers
import CoreGraphics
import SortEngineKit
import Testing
import VisualizationKit

/// Validates the geometry source that each Metal layout was ported from across inputs the
/// settled-pixel hash fixture does not cover: repeated values, a degenerate value range, and
/// a large array. The list is literal so adding a built-in style requires updating this test.
struct VisualizerGeometryCorpusTests {
  private static let styles: [any Visualizer] = [
    BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer(), SineWaveVisualizer(),
    ColorCircleVisualizer(), SpiralVisualizer(), SpiralDotsVisualizer(), WaveDotsVisualizer(),
    PixelMeshVisualizer(), HoopStackVisualizer(), DisparityBarGraphVisualizer(),
    DisparityCircleVisualizer(), DisparityChordsVisualizer(), DisparityDotsVisualizer(),
    HanoiTowersVisualizer(),
    CustomImageVisualizer(),
  ]

  @Test(arguments: [16, 256, 1024])
  func everyStyleEmitsFiniteCanvasGeometryForRepeatedAndPermutedValues(count: Int) {
    let canvas = CGSize(width: 400, height: 300)
    let cases: [([Int], ClosedRange<Int>)] = [
      ((0 ..< count).map { $0 % 8 + 1 }, 1 ... 8),
      ([Int](repeating: 4, count: count), 4 ... 4),
      ((0 ..< count).map { ($0 * 17) % count + 1 }, 1 ... count),
    ]

    for style in Self.styles {
      for (values, range) in cases {
        let context = VisualizationContext(
          values: values, valueRange: range,
          markers: [0: [Marker.primary], count - 1: [Marker.secondary]],
          auxArrays: [:], canvasSize: canvas, colorSeed: 42
        )
        let commands = style.draw(context)
        #expect(!commands.isEmpty, "\(style.id.rawValue), count=\(count), range=\(range)")
        for command in commands {
          #expect(isFiniteAndInside(command, canvas: canvas),
                  "\(style.id.rawValue), count=\(count), range=\(range): \(command)")
        }
      }
    }
  }

  @Test
  func crowdedDotStylesFitEvenAThinCanvas() {
    let canvas = CGSize(width: 4, height: 3)
    let values = (0 ..< 1024).map { $0 % 8 + 1 }
    let context = VisualizationContext(
      values: values, valueRange: 1 ... 8, markers: [:], auxArrays: [:],
      canvasSize: canvas, colorSeed: 42
    )
    for style in [ScatterPlotVisualizer() as any Visualizer, WaveDotsVisualizer()] {
      let commands = style.draw(context)
      #expect(commands.count == values.count)
      for command in commands {
        #expect(isFiniteAndInside(command, canvas: canvas), "\(style.id.rawValue): \(command)")
      }
    }
  }

  private func isFiniteAndInside(_ command: DrawCommand, canvas: CGSize) -> Bool {
    let width = Double(canvas.width)
    let height = Double(canvas.height)
    let tolerance = 0.001
    func point(_ x: Double, _ y: Double) -> Bool {
      x.isFinite && y.isFinite && x >= -tolerance && y >= -tolerance
        && x <= width + tolerance && y <= height + tolerance
    }
    func color(_ value: RGBAColor) -> Bool {
      [value.red, value.green, value.blue, value.alpha].allSatisfy {
        $0.isFinite && (0 ... 1).contains($0)
      }
    }
    switch command {
    case let .rect(x, y, w, h, c),
         let .ellipse(x, y, w, h, c):
      return w.isFinite && h.isFinite && w >= 0 && h >= 0
        && point(x, y) && point(x + w, y + h) && color(c)
    case let .line(x1, y1, x2, y2, c, lineWidth):
      return point(x1, y1) && point(x2, y2) && lineWidth.isFinite && lineWidth >= 0 && color(c)
    case let .polygon(points, c):
      return !points.isEmpty && points.allSatisfy { point($0.x, $0.y) } && color(c)
    case let .text(x, y, _, c):
      return point(x, y) && color(c)
    case let .imageTile(x, y, w, h, sourceSlot, marker):
      return w.isFinite && h.isFinite && w >= 0 && h >= 0
        && point(x, y) && point(x + w, y + h)
        && sourceSlot >= 0 && (0...2).contains(marker)
    }
  }
}
