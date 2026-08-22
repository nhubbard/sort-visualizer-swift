import CoreGraphics
import SortEngineKit
import Testing

@testable import BuiltInVisualizers
@testable import VisualizationKit

@Suite
struct HanoiTowersVisualizerTests {
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
  func emitsOneRectPerValue() {
    let context = makeContext(values: [1, 2, 3, 4, 5])
    let commands = HanoiTowersVisualizer().draw(context)

    #expect(commands.count == 5)
    for command in commands {
      guard case .rect = command else {
        Issue.record("expected .rect")
        return
      }
    }
  }

  @Test
  func towerAssignmentIsMonotonicInIndex() {
    let count = 40
    let towers = HanoiTowersVisualizer.towerCount(for: count)
    var lastTower = 0
    for index in 0..<count {
      let tower = HanoiTowersVisualizer.tower(forIndex: index, count: count, towerCount: towers)
      #expect(tower >= lastTower, "tower assignment must never move backward as index increases")
      #expect(tower < towers)
      lastTower = tower
    }
  }

  @Test
  func everyTowerIsUsedAtLeastOnce() {
    let count = 30
    let towers = HanoiTowersVisualizer.towerCount(for: count)
    let used = Set(
      (0..<count).map { HanoiTowersVisualizer.tower(forIndex: $0, count: count, towerCount: towers) })
    #expect(used.count == towers, "every tower should hold at least one index for a reasonably-sized array")
  }

  @Test
  func blocksWithinATowerStackUpwardWithoutOverlap() {
    let context = makeContext(values: Array(1...12), canvasSize: CGSize(width: 120, height: 120))
    let commands = HanoiTowersVisualizer().draw(context)

    var rectsByX: [Double: [(y: Double, height: Double)]] = [:]
    for command in commands {
      guard case .rect(let x, let y, _, let height, _) = command else {
        Issue.record("expected .rect")
        return
      }
      rectsByX[x, default: []].append((y, height))
    }

    for (_, rects) in rectsByX {
      let sortedByY = rects.sorted { $0.y > $1.y }
      for index in 0..<(sortedByY.count - 1) {
        let lowerTop = sortedByY[index].y
        let upperBottom = sortedByY[index + 1].y + sortedByY[index + 1].height
        #expect(upperBottom <= lowerTop + 0.0001, "stacked blocks in the same tower must not overlap")
      }
    }
  }

  @Test
  func valueDrivesHueRampColor() {
    let context = makeContext(values: [1, 4], valueRange: 1...4)
    let commands = HanoiTowersVisualizer().draw(context)

    guard case .rect(_, _, _, _, let color0) = commands[0],
      case .rect(_, _, _, _, let color1) = commands[1]
    else {
      Issue.record("expected .rect")
      return
    }
    #expect(color0 == RGBAColor.hueRamp(0.0))
    #expect(color1 == RGBAColor.hueRamp(1.0))
  }

  @Test
  func colorsReflectMarkerState() {
    let context = makeContext(
      values: [5, 5, 5], markers: [0: [Marker.primary], 1: [Marker.secondary]])
    let commands = HanoiTowersVisualizer().draw(context)

    guard case .rect(_, _, _, _, let color0) = commands[0],
      case .rect(_, _, _, _, let color1) = commands[1],
      case .rect(_, _, _, _, let color2) = commands[2]
    else {
      Issue.record("expected .rect")
      return
    }
    #expect(color0 != color1)
    #expect(color1 != color2)
  }

  @Test
  func emptyValuesProducesNoCommands() {
    #expect(HanoiTowersVisualizer().draw(makeContext(values: [], valueRange: 0...1)).isEmpty)
  }

  @Test
  func degenerateCanvasSizeProducesNoCommands() {
    #expect(HanoiTowersVisualizer().draw(makeContext(values: [1, 2], canvasSize: .zero)).isEmpty)
  }
}
