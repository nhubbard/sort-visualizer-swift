import AlgorithmKit
import SortEngineKit
import Testing
@testable import IntentsKit

private struct FakeAlgorithm: SortAlgorithm {
    let id: AlgorithmID
    let category: AlgorithmCategory
    var metadata: AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: id.rawValue, category: category, sizeRange: 1...64, stable: true,
            timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
            spaceComplexity: "O(1)", iconName: "fake")
    }
    func record(into engine: inout RecordingEngine) {}
}

@MainActor
@Suite
struct FindAlgorithmsIntentTests {
    /// Fully synchronous between saving/mutating/restoring `AlgorithmRegistry.shared.builtIns` and
    /// reading the result — same precedent `AppSettingsTests.cycleVisualizerWrapsAroundLikeARingBuffer`
    /// already established for this process-wide singleton, so this can't interleave with another
    /// `@MainActor` test's own mutation of it.
    @Test
    func categoryFilterOnlyReturnsThatCategorysAlgorithms() async throws {
        let registry = AlgorithmRegistry.shared
        let restoreBuiltIns = registry.builtIns
        defer {
            registry.builtIns = restoreBuiltIns
            registry.discover()
        }
        registry.builtIns = [
            FakeAlgorithm(id: AlgorithmID(rawValue: "b-quick"), category: .quick),
            FakeAlgorithm(id: AlgorithmID(rawValue: "a-quick"), category: .quick),
            FakeAlgorithm(id: AlgorithmID(rawValue: "some-merge"), category: .merge),
        ]
        registry.discover()

        let filtered = try await FindAlgorithmsIntent(category: .quick).perform()
        let all = try await FindAlgorithmsIntent(category: .all).perform()

        #expect(filtered.value?.map(\.id).sorted() == ["a-quick", "b-quick"])
        #expect(all.value?.count == 3)
        // Alphabetical by displayName (== id here), matching AlgorithmRegistry.algorithms(in:)'s
        // own sidebar-facing sort order.
        #expect(filtered.value?.map(\.id) == ["a-quick", "b-quick"])
    }
}
