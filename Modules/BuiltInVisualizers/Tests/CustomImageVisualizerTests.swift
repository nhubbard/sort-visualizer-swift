import CoreGraphics
import SortEngineKit
import Testing
import VisualizationKit

@testable import BuiltInVisualizers

struct CustomImageVisualizerTests {
  @Test(arguments: [1, 5, 128, 256, 8192])
  func sortedPermutationReassemblesEveryTile(count: Int) {
    let values = Array(1...count)
    let layout = ImageTileLayout(count: count, aspectRatio: 1)
    for slot in 0..<layout.cellCount {
      #expect(layout.sourceSlot(forDestination: slot, values: values,
                                valueRange: 1...count) == slot)
    }
    #expect(layout.cellCount >= count)
    #expect(layout.cellCount - count < layout.columns)
  }

  @Test
  func shuffledValuesMoveImageFragmentsAndDuplicatesRepeatThem() {
    let layout = ImageTileLayout(count: 5, aspectRatio: 1)
    let values = [3, 1, 3, 5, 2]
    #expect((0..<5).map {
      layout.sourceSlot(forDestination: $0, values: values, valueRange: 1...5)
    } == [2, 0, 2, 4, 1])
    #expect(layout.cellCount == 6)
    #expect(layout.sourceSlot(forDestination: 5, values: values, valueRange: 1...5) == 5)
  }

  @Test
  func geometryAndMarkersFollowDestinationCells() {
    let context = VisualizationContext(
      values: [2, 1, 3, 4, 5], valueRange: 1...5,
      markers: [0: [Marker.primary], 1: [Marker.secondary]], auxArrays: [:],
      canvasSize: CGSize(width: 300, height: 200), colorSeed: 0)
    let commands = CustomImageVisualizer().draw(context)
    #expect(commands.count == 6)
    guard case let .imageTile(x0, y0, w0, h0, source0, marker0) = commands[0],
          case let .imageTile(x1, y1, _, _, source1, marker1) = commands[1],
          case let .imageTile(_, _, _, _, fixedSource, fixedMarker) = commands[5]
    else {
      Issue.record("Expected image tile commands")
      return
    }
    #expect((x0, y0, w0, h0) == (0, 0, 100, 100))
    #expect((x1, y1) == (100, 0))
    #expect((source0, source1, fixedSource) == (1, 0, 5))
    #expect((marker0, marker1, fixedMarker) == (1, 2, 0))
  }
}
