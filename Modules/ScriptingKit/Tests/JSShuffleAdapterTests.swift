import AlgorithmKit
import SortEngineKit
import Testing
@testable import ScriptingKit

@Suite
struct JSShuffleAdapterTests {
    private func makeAdapter(source: String) -> JSShuffleAdapter {
        JSShuffleAdapter(
            id: ShuffleID(rawValue: "test"), metadata: ShuffleMetadata(displayName: "Test"), source: source
        )
    }

    @Test
    func entryPointIsShuffleNotSort() throws {
        // A script that only defines `sort` (not `shuffle`) must fail — proves JSShuffleAdapter
        // calls a different entry point than JSAlgorithmAdapter, not just reusing "sort" by accident.
        let adapter = makeAdapter(source: "function sort(engine) { engine.swap(0, 1); }")
        var engine = RecordingEngine(values: [1, 2, 3])

        #expect(throws: ScriptExecutionError.self) {
            try adapter.recordThrowing(into: &engine)
        }
    }

    @Test
    func reverseShuffleProducesExactExpectedPermutation() throws {
        let adapter = makeAdapter(source: """
        function shuffle(engine) {
            const n = engine.count();
            for (let i = 0; i < Math.floor(n / 2); i++) {
                engine.swap(i, n - 1 - i);
            }
        }
        """)
        var engine = RecordingEngine(values: [1, 2, 3, 4, 5])
        try adapter.recordThrowing(into: &engine)

        #expect(engine.values == [5, 4, 3, 2, 1])
    }

    @Test
    func infiniteLoopIsTerminatedByExecutionWatchdogInsteadOfHanging() {
        var engine = RecordingEngine(values: [3, 1, 2])
        let adapter = makeAdapter(source: "function shuffle(engine) { while (true) {} }")

        #expect(throws: ScriptExecutionError.self) {
            try adapter.recordThrowing(into: &engine, timeout: 0.5)
        }
    }
}
