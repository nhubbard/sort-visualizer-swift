import AlgorithmKit
import SortEngineKit

public struct SnuffleSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "snufflesort")
    /// `16...32`, deliberately narrow — each outer recursion level re-snuffles two overlapping
    /// halves `(stop - start + 1) / 2` times, so the call count compounds far faster than a typical
    /// `O(n^{\log n})`-flavored recursive sort. Empirically (simulated separately from
    /// `RecordingEngine`, counting compares + swaps): a reverse-sorted run of 32 elements takes
    /// ~52K recorded operations, comparable to `SlowSort`'s own footprint at its `sizeRange` max —
    /// but growth here is much steeper, reaching ~3.4M operations by 64 and ~436M by 128 (matching
    /// why ArrayV itself flags this `unreasonablySlow` with a limit of 100). 32 is chosen as the
    /// practical ceiling for this engine's fully-instrumented recording, same reasoning `SlowSort`
    /// used to justify its own narrower-than-ArrayV's cap.
    public let metadata = AlgorithmMetadata(
        displayName: "Snuffle Sort",
        category: .exchange,
        sizeRange: 16...32,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n^{log n})", average: "O(n^{log n})", worst: "O(n^{log n})"),
        spaceComplexity: "O(log n)",
        iconName: "pawprint.fill"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        snuffleSort(&engine, 0, engine.count - 1)
    }

    /// Ported from ArrayV's `SnuffleSort.snuffleSort(arr, start, stop)`. Compares/swaps the two
    /// ends of the inclusive range `[start, stop]`, then — for ranges of 3 or more elements —
    /// recursively re-snuffles the overlapping halves `[start, mid]`/`[mid, stop]` (both sides
    /// include `mid`) a number of times equal to `(stop - start + 1) / 2`.
    ///
    /// That iteration count is a faithful port of a real quirk in the Java source:
    /// `Math.ceil((stop - start + 1) / 2)` computes `(stop - start + 1) / 2` as **integer**
    /// division first (both operands are `int`), then hands `Math.ceil` an already-truncated
    /// whole number to round — a no-op. The visible `Math.ceil` call never actually rounds
    /// anything up; the real iteration count is plain floor division, which is what this port
    /// uses directly rather than reproducing the misleading `ceil` call.
    private func snuffleSort(_ engine: inout RecordingEngine, _ start: Int, _ stop: Int) {
        guard stop - start + 1 >= 2 else { return }

        if engine.compare(start, stop, by: (>)) {
            engine.swap(start, stop)
        }

        if stop - start + 1 >= 3 {
            let mid = (stop - start) / 2 + start
            let iterations = (stop - start + 1) / 2
            for _ in 0..<iterations {
                snuffleSort(&engine, start, mid)
                snuffleSort(&engine, mid, stop)
            }
        }
    }
}
