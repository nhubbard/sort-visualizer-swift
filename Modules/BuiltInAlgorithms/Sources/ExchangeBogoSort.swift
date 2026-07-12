import AlgorithmKit
import SortEngineKit

public struct ExchangeBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "exchangebogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Exchange Bogo Sort",
        category: .impractical,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "die.face.3.fill"
    )
    public init() {}

    /// ArrayV's `ExchangeBogoSort` picks two uniformly random indices every iteration and swaps
    /// them only if they're out of order, repeating until the whole array happens to be sorted.
    /// Unlike classic `BogoSort`/`BozoSort` (which gamble on a full arrangement or a single swap
    /// landing on *fully* sorted), every accepted swap here strictly fixes one inversion — but the
    /// random *pair* chosen each step can still be a no-op (already in order), so the real
    /// algorithm's step count is an open-ended random variable with no hard ceiling, the same
    /// `RecordingEngine`-can't-pre-record-an-unbounded-tape problem documented on `BogoSort`.
    ///
    /// Rather than a permutation-walk substitute (which wouldn't fit this algorithm's "fix
    /// inversions one pair at a time" character), this deterministically visits every pair
    /// `(i, j)` with `i < j` exactly once in a fixed nested order and fixes it if inverted —
    /// same "spot an inversion, resolve it" behavior as the random version, just without leaving
    /// it to chance which pair gets checked when. For a fixed `i`, scanning every `j > i` and
    /// swapping whenever `values[j] < values[i]` leaves `values[i]` holding the minimum of
    /// `[i, n)` by the time the inner loop finishes — so a single O(n^2) pass, with no repeats and
    /// no wrapping, fully sorts the array.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func isSorted() -> Bool {
            for i in 1..<n where engine.compare(i, i - 1, by: (<)) { return false }
            return true
        }

        if isSorted() { return }

        for i in 0..<(n - 1) {
            for j in (i + 1)..<n where engine.compare(j, i, by: (<)) {
                engine.swap(i, j)
            }
        }
    }
}
