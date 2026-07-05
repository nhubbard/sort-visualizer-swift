import AlgorithmKit
import SortEngineKit
import Testing
@testable import ScriptingKit

/// Test-only, never shipped in `BuiltInAlgorithms` (§7) — mirrors
/// `App/Resources/Algorithms/bubblesort.js` exactly, purely to prove the JS bridge produces an
/// identical operation sequence to a native implementation for the same input.
private struct BubbleSortReference: SortAlgorithm {
    let id = AlgorithmID(rawValue: "bubblesort-reference")
    let metadata = AlgorithmMetadata(
        displayName: "Bubble Sort (native reference)",
        category: .quadratic,
        sizeRange: 1...512,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "bubble"
    )

    func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        for i in 1..<engine.count {
            for j in 0..<(engine.count - i) where engine.compare(j, j + 1) {
                engine.swap(j, j + 1)
            }
        }
    }
}

/// Must stay byte-for-byte in sync with `App/Resources/Algorithms/bubblesort.js`.
private let bubbleSortJS = """
function sort(engine) {
    const n = engine.count();
    for (let i = 1; i < n; i++) {
        for (let j = 0; j < n - i; j++) {
            if (engine.compare(j, j + 1)) {
                engine.swap(j, j + 1);
            }
        }
    }
}
"""

@Suite
struct JSAlgorithmAdapterTests {
    private func makeAdapter(source: String) -> JSAlgorithmAdapter {
        JSAlgorithmAdapter(
            id: AlgorithmID(rawValue: "bubblesort"),
            metadata: BubbleSortReference().metadata,
            source: source
        )
    }

    @Test(arguments: [[5, 3, 8, 1, 9, 2, 7, 4, 6, 0], [1], [], [3, 3, 3], Array((0..<50).reversed())])
    func jsAndNativeBubbleSortProduceIdenticalOperationSequences(input: [Int]) throws {
        var jsEngine = RecordingEngine(values: input)
        try makeAdapter(source: bubbleSortJS).recordThrowing(into: &jsEngine)

        var nativeEngine = RecordingEngine(values: input)
        BubbleSortReference().record(into: &nativeEngine)

        #expect(jsEngine.finish().tape == nativeEngine.finish().tape)
        #expect(jsEngine.values == input.sorted())
    }

    @Test
    func infiniteLoopIsTerminatedByExecutionWatchdogInsteadOfHanging() {
        var engine = RecordingEngine(values: [3, 1, 2])
        let adapter = makeAdapter(source: "function sort(engine) { while (true) {} }")

        #expect(throws: ScriptExecutionError.self) {
            try adapter.recordThrowing(into: &engine, timeout: 0.5)
        }
    }

    @Test
    func malformedScriptSurfacesAsThrownErrorNotACrash() {
        var engine = RecordingEngine(values: [3, 1, 2])
        let adapter = makeAdapter(source: "this is not valid javascript {{{")

        #expect(throws: ScriptExecutionError.self) {
            try adapter.recordThrowing(into: &engine)
        }
    }

    /// The bridge only ever exposed compare/swap/getValue/setValue/count/markSorted until this
    /// Phase 7 batch needed aux arrays for LSD Radix Sort — this locks in the rest of the surface
    /// (aux arrays, manual mark/unmark) actually reaches `RecordingEngine` correctly.
    @Test
    func auxArraysAndManualMarksReachTheRecordingEngine() throws {
        var engine = RecordingEngine(values: [3, 1, 2])
        let adapter = makeAdapter(source: """
        function sort(engine) {
            engine.mark(7, 0);
            const handle = engine.createAuxArray(2);
            engine.writeAux(handle, 0, 99);
            engine.writeAux(handle, 1, 42);
            engine.deleteAuxArray(handle);
            engine.unmark(7);
            engine.unmarkAll();
        }
        """)
        try adapter.recordThrowing(into: &engine)

        let (tape, _, _, auxWriteCount) = engine.finish()
        #expect(tape == [
            .mark(marker: 7, index: 0),
            .auxCreate(handle: 0, length: 2),
            .auxWrite(handle: 0, index: 0, value: 99),
            .auxWrite(handle: 0, index: 1, value: 42),
            .auxDelete(handle: 0),
            .unmark(marker: 7),
            .unmarkAll,
        ])
        #expect(auxWriteCount == 2)
    }
}
