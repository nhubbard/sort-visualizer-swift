import SortEngineKit
import Testing

@testable import AlgorithmKit

private struct FakeAlgorithm: SortAlgorithm {
  let id: AlgorithmID
  let metadata: AlgorithmMetadata

  init(id: AlgorithmID, name: String = "Fake", category: AlgorithmCategory = .exchange) {
    self.id = id
    metadata = AlgorithmMetadata(
      displayName: name,
      category: category,
      sizeRange: 1...10,
      growthModel: .unconstrained,
      implementationComplexity: 0,
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
  }

  func record(into engine: inout RecordingEngine) {}
}

@MainActor
@Suite
struct AlgorithmRegistryTests {
  @Test
  func discoverPopulatesAlgorithmsFromBuiltIns() {
    let registry = AlgorithmRegistry()
    registry.builtIns = [FakeAlgorithm(id: AlgorithmID(rawValue: "native"))]

    #expect(registry.algorithms.isEmpty)
    registry.discover()
    #expect(registry.algorithms.map(\.id.rawValue) == ["native"])
  }

  @Test
  func algorithmLookupByIDFindsMatchOrReturnsNil() {
    let registry = AlgorithmRegistry()
    registry.builtIns = [FakeAlgorithm(id: AlgorithmID(rawValue: "quicksort"))]
    registry.discover()

    #expect(registry.algorithm(id: AlgorithmID(rawValue: "quicksort")) != nil)
    #expect(registry.algorithm(id: AlgorithmID(rawValue: "missing")) == nil)
  }

  @Test
  func categoryOrderIsStableAndRediscoveryRemovesRetiredAlgorithms() {
    let registry = AlgorithmRegistry()
    let alpha = FakeAlgorithm(id: AlgorithmID(rawValue: "alpha"), name: "Shared")
    let beta = FakeAlgorithm(id: AlgorithmID(rawValue: "beta"), name: "Shared")
    let first = FakeAlgorithm(id: AlgorithmID(rawValue: "first"), name: "First")
    let otherCategory = FakeAlgorithm(
      id: AlgorithmID(rawValue: "other"), name: "Other", category: .merge)
    registry.builtIns = [beta, otherCategory, alpha, first]
    registry.discover()

    #expect(registry.algorithms(in: .exchange).map(\.id.rawValue) == ["first", "alpha", "beta"])
    #expect(registry.algorithms(in: .merge).map(\.id.rawValue) == ["other"])
    #expect(registry.algorithms.map(\.id.rawValue) == ["beta", "other", "alpha", "first"])

    registry.builtIns.removeAll { $0.id == beta.id }
    registry.discover()
    #expect(registry.algorithm(id: beta.id) == nil)
    #expect(registry.algorithms(in: .exchange).map(\.id.rawValue) == ["first", "alpha"])
  }
}
