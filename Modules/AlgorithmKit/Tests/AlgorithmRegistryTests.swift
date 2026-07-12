import SortEngineKit
import Testing
@testable import AlgorithmKit

private struct FakeAlgorithm: SortAlgorithm {
    let id: AlgorithmID
    let metadata = AlgorithmMetadata(
        displayName: "Fake",
        category: .exchange,
        sizeRange: 1...10,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
        spaceComplexity: "O(1)",
        iconName: "fake"
    )

    func record(into engine: inout RecordingEngine) {}
}

@MainActor
@Suite
struct AlgorithmRegistryTests {
    @Test
    func discoverCombinesBuiltInsAndScriptLoader() {
        let registry = AlgorithmRegistry()
        registry.builtIns = [FakeAlgorithm(id: AlgorithmID(rawValue: "native"))]
        registry.scriptLoader = { [FakeAlgorithm(id: AlgorithmID(rawValue: "scripted"))] }

        #expect(registry.algorithms.isEmpty)
        registry.discover()
        #expect(registry.algorithms.map(\.id.rawValue) == ["native", "scripted"])
    }

    @Test
    func discoverWithNoScriptLoaderYieldsBuiltInsAlone() {
        let registry = AlgorithmRegistry()
        registry.builtIns = [FakeAlgorithm(id: AlgorithmID(rawValue: "native"))]

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
}
