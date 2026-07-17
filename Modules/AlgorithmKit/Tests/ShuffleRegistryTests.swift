import SortEngineKit
import Testing

@testable import AlgorithmKit

private struct FakeShuffle: ShuffleAlgorithm {
  let id: ShuffleID
  let metadata = ShuffleMetadata(displayName: "Fake")

  func record(into engine: inout RecordingEngine) {}
}

@MainActor
@Suite
struct ShuffleRegistryTests {
  @Test
  func discoverPopulatesShufflesFromBuiltIns() {
    let registry = ShuffleRegistry()
    registry.builtIns = [FakeShuffle(id: ShuffleID(rawValue: "native"))]

    #expect(registry.shuffles.isEmpty)
    registry.discover()
    #expect(registry.shuffles.map(\.id.rawValue) == ["native"])
  }

  @Test
  func shuffleLookupByIDFindsMatchOrReturnsNil() {
    let registry = ShuffleRegistry()
    registry.builtIns = [FakeShuffle(id: ShuffleID(rawValue: "random"))]
    registry.discover()

    #expect(registry.shuffle(id: ShuffleID(rawValue: "random")) != nil)
    #expect(registry.shuffle(id: ShuffleID(rawValue: "missing")) == nil)
  }
}
