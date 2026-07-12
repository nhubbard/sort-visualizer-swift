import AlgorithmKit
import SortEngineKit
import Testing
@testable import ShowcaseFeature

/// Deliberately doesn't exercise `start()`'s actual `Task` — that drives a real `SortSession`/
/// `ReplayEngine` end to end, whose completion is only ever observed via a genuine `CADisplayLink`
/// tick (see `SortSessionTests.swift`'s `ManualTickDriver` doc comment on why a host-less
/// `.unitTests` bundle has no guaranteed tick latency at all). `ShowcaseController` doesn't expose
/// a `replayEngineFactory` injection seam the way `SortSession` does, so there's no safe way to
/// let that `Task` actually run here without risking a hang.
@MainActor
@Suite
struct ShowcaseControllerTests {
    @Test
    func algorithmsAreSortedByDisplayNameRegardlessOfRegistrationOrder() {
        let registry = AlgorithmRegistry.shared
        let restoreBuiltIns = registry.builtIns
        defer {
            registry.builtIns = restoreBuiltIns
            registry.discover()
        }
        registry.builtIns = ["Zebra", "Apple", "Mango"].map(FakeAlgorithm.init)
        registry.discover()

        let controller = ShowcaseController()
        #expect(controller.algorithms.map(\.metadata.displayName) == ["Apple", "Mango", "Zebra"])
    }

    @Test
    func stopBeforeStartIsANoOp() {
        let controller = ShowcaseController()
        controller.stop()
        #expect(controller.isRunning == false)
        #expect(controller.currentSession == nil)
    }
}

private struct FakeAlgorithm: SortAlgorithm {
    let id: AlgorithmID
    let displayName: String

    init(_ displayName: String) {
        self.id = AlgorithmID(rawValue: displayName.lowercased())
        self.displayName = displayName
    }

    var metadata: AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: displayName,
            category: .exchange,
            sizeRange: 1...8,
            stable: true,
            timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
            spaceComplexity: "O(1)",
            iconName: "fake"
        )
    }

    func record(into engine: inout RecordingEngine) {}
}
