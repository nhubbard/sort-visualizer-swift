import AlgorithmKit
import SortEngineKit

/// ArrayV's `GravitySort` ("Beadsort"): models Bead Sort — beads dropped onto vertical rods, one
/// rod per array position, with as many beads on a rod as the value it represents; once released,
/// the beads fall and settle into a sorted "staircase" — but instead of literally simulating rows
/// of falling beads, it reaches the same final array through an equivalent tally-and-partial-sum
/// computation. `x` is a shifted copy of the input (`array[i] - min`, so every shifted value is
/// non-negative and indexable). `y[v]` starts as a per-value occurrence tally, then a *backward*
/// partial sum turns it into "how many elements have shifted-value >= v" — in the physical bead
/// model, this is exactly how many beads would be resting at or above height `v` once gravity has
/// settled them, without ever tracking rod-by-rod bead positions directly. The final double loop
/// then reconstructs each `array[i]` incrementally: walking value levels `j` from highest to
/// lowest, position `i` gains `+1` once `i` falls among the rightmost `y[j]` slots (the slots
/// known, from the tally, to end up `>= j`), and loses that same `+1` back out via `-1` if `i`'s
/// *original* shifted value was itself already `>= j` (so the "this element already started at or
/// above this level" contribution isn't double-counted as gravity settles it further down).
///
/// This reconstruction has no notion of which original element ends up at which final position
/// beyond value — nothing here threads an original index or insertion order through to the write
/// loop — so, like `PigeonholeSort`, this is NOT a stable sort.
public struct GravitySort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "gravitysort")
    public let metadata = AlgorithmMetadata(
        displayName: "Gravity (Bead) Sort",
        category: .distribution,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n \\times k)", average: "O(n \\times k)", worst: "O(n \\times k)"),
        spaceComplexity: "O(n+k)",
        iconName: "arrow.down.circle.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // ArrayV's min/max scan reads values directly (no stat-tracked compares), so this reads
        // `engine.values` and compares against the plain local `min`/`max` variables rather than
        // going through `engine.compare` — the same held-value pattern as `CycleSort`'s `t` and
        // `PigeonholeSort`'s own min/max scan.
        var minValue = engine.values[0]
        var maxValue = engine.values[0]
        for i in 1..<n {
            if engine.values[i] < minValue { minValue = engine.values[i] }
            if engine.values[i] > maxValue { maxValue = engine.values[i] }
        }

        let mi = minValue
        let ySize = maxValue - mi + 1

        // `x` and `y` are two separate ArrayV external arrays; `RecordingEngine.writeAux` has no
        // read-back method, so a local Swift shadow array tracks each one's running values
        // alongside the `.writeAux` calls that make them visible in the replay — same precedent as
        // `CountingSort`'s local `counts`/`output` shadow arrays.
        let xHandle = engine.createAuxArray(length: n)
        var x = [Int](repeating: 0, count: n)
        let yHandle = engine.createAuxArray(length: ySize)
        var y = [Int](repeating: 0, count: ySize)

        // Save a shifted copy of the input in `x`, and tally the count of each shifted value in
        // `y`.
        for i in 0..<n {
            let shifted = engine.values[i] - mi
            x[i] = shifted
            engine.writeAux(xHandle, at: i, value: shifted)

            y[shifted] += 1
            engine.writeAux(yHandle, at: shifted, value: y[shifted])
        }

        // A backward partial sum turns "count of elements with this exact shifted value" into
        // "count of elements with shifted value >= this one".
        for i in stride(from: ySize - 1, to: 0, by: -1) {
            y[i - 1] += y[i]
            engine.writeAux(yHandle, at: i - 1, value: y[i - 1])
        }

        // Walk every possible shifted value from highest to lowest, updating every array position
        // in place — each pass over `i` either credits position `i` with reaching this level (if
        // `i` is one of the rightmost `y[j]` positions known to end up `>= j`) or debits it back
        // out (if position `i`'s original shifted value already started `>= j`, so it shouldn't be
        // credited again on the way down).
        for j in stride(from: ySize - 1, through: 0, by: -1) {
            for i in 0..<n {
                let inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0)
                engine.setValue(i, engine.values[i] + inc)
            }
        }

        engine.deleteAuxArray(xHandle)
        engine.deleteAuxArray(yHandle)
    }
}
