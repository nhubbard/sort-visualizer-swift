import Testing

@testable import VisualizationKit

private struct FakeVisualizer: Visualizer {
  let id: VisualizerID
  let metadata = VisualizerMetadata(displayName: "Fake", supportsAuxArrays: false, iconName: "fake")

  func draw(_ context: VisualizationContext) -> [DrawCommand] { [] }
}

@MainActor
@Suite
struct VisualizerRegistryTests {
  @Test
  func discoverPopulatesFromBuiltIns() {
    let registry = VisualizerRegistry()
    registry.builtIns = [
      FakeVisualizer(id: VisualizerID(rawValue: "a")),
      FakeVisualizer(id: VisualizerID(rawValue: "b")),
    ]

    #expect(registry.visualizers.isEmpty)
    registry.discover()
    #expect(registry.visualizers.map(\.id.rawValue) == ["a", "b"])
  }

  @Test
  func visualizerLookupByIDFindsMatchOrReturnsNil() {
    let registry = VisualizerRegistry()
    registry.builtIns = [FakeVisualizer(id: VisualizerID(rawValue: "bargraph"))]
    registry.discover()

    #expect(registry.visualizer(id: VisualizerID(rawValue: "bargraph")) != nil)
    #expect(registry.visualizer(id: VisualizerID(rawValue: "missing")) == nil)
  }
}
