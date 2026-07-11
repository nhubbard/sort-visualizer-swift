import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `io.github.arrayv.sorts.select.BadSort` (`sorts/select/BadSort.java`) — a
/// deliberately wasteful selection sort lifted from a StackOverflow answer (James Jensen, a.k.a.
/// "StriplingWarrior") to a question asking for a real *O*(*n*^3) worst-case sort:
/// <https://stackoverflow.com/questions/27389344/is-there-a-sorting-algorithm-with-a-worst-case-time-complexity-of-n3>.
///
/// ## Mechanism: "prove no smaller element exists ahead," the hard way
///
/// For each `i`, the inner double loop hunts for the leftmost index `j >= i` whose value is a
/// **suffix minimum** of `values[i..<n]` — i.e. no element anywhere after `j` is *strictly*
/// smaller than `values[j]`. It does this by brute force: for each candidate `j` (starting at `i`
/// and walking rightward), the `k`-loop scans every later index looking for a single
/// counterexample. The moment `values[k] < values[j]` for some `k > j`, `j` is disqualified
/// (`isShortest = false`) and the `k`-scan aborts early — but if the `k`-scan runs to completion
/// without ever finding one, `j` is confirmed to be the answer and the `j`-loop itself stops.
/// Whatever `j` that turns out to be gets swapped into position `i`.
///
/// By induction this `j` always lands on `p`, the leftmost index `>= i` holding
/// `min(values[i..<n])`: any `j < p` must have `values[j] > values[p]` (`p` is defined as the
/// *leftmost* occurrence of that minimum, so anything strictly before it in the same subrange is
/// strictly greater), so `j`'s `k`-scan finds `k = p` — or some earlier counterexample — and
/// disqualifies it; at `j = p` itself, nothing after it is smaller by definition of minimum, so
/// `isShortest` survives to the end of the scan. So `BadSort` is an ordinary leftmost-minimum-wins
/// selection sort under the hood — it is just computing "is this the minimum?" via an *O*(*n*)
/// brute-force proof instead of a running-minimum tracker, purely to manufacture a cubic worst
/// case. `Reads.compareValues(array[j], array[k]) == 1` in the Java is a strict greater-than
/// comparison between two *live* array reads that ArrayV still marks for the visualizer (via the
/// explicit `Highlights.markArray(1, j)` / `Highlights.markArray(2, k)` calls immediately
/// preceding it, rather than through `Reads.compareIndices`'s built-in marking) — the same
/// "manually marked, but still a live index-vs-index compare" shape `DoubleSelectionSort` already
/// ports as `engine.compare(_:_:by:)`, so the `k`-loop's compare below does the same rather than
/// reading `engine.values` directly.
///
/// ## Complexity: genuinely asymmetric, verified by op-counting, not just theory
///
/// The naive "each `k`-scan is *O*(*n*), the `j`-loop runs up to *n* times, and there are *n*
/// values of `i`" argument gives *O*(*n*^3) as a blanket bound, but both inner loops can break
/// early, and how often they actually do so is very input-dependent — checked here by literally
/// counting `k`-loop comparisons (a standalone, non-`RecordingEngine` Swift harness mirroring this
/// exact loop shape, run across sorted/reverse/adversarial/random inputs at several sizes; see the
/// batch's verification notes for the harness itself) rather than trusting the StackOverflow post's
/// headline claim to apply uniformly:
///
/// - **Best case — already-sorted ascending input — is *Θ*(*n*^2), not sub-quadratic.** Every
///   `values[i]` already *is* the suffix minimum, so the `j`-loop always stops after exactly one
///   attempt (`j = i`). But confirming that single attempt still costs a full, unbroken `k`-scan
///   of length `n - 1 - i` (a "yes" answer can never break early — the whole point of the scan is
///   to rule out every later counterexample, so ruling out zero of them still means checking all
///   of them). Summed over `i`, that is exactly `Σ(n - 1 - i) = n(n-1)/2` — confirmed to the exact
///   integer by the op-counting harness at every tested size (e.g. exactly 32,640 `k`-loop
///   compares at `n = 256`, matching the closed form bit for bit).
/// - **Reverse-sorted (descending) input is *also* exactly *Θ*(*n*^2) with the identical
///   `n(n-1)/2` count** — measured bit-for-bit identical to the ascending case at every size
///   tested — but for a completely different structural reason: at each `i`, every `j` from `i` up
///   to `n - 2` is disqualified in exactly one comparison (`values[j] > values[j + 1]` is
///   immediately true, since the suffix is strictly descending), and the final `j = n - 1` confirms
///   in zero comparisons (an empty `k`-range). That is `(n - 1 - i)` one-comparison attempts per
///   `i`, which sums to the same `n(n-1)/2` total as the best case despite arising from "many cheap
///   rejections" rather than "one expensive confirmation."
/// - **Worst case is genuinely *Θ*(*n*^3)**, but only for a specific adversarial shape: at every
///   level `i`, the leftmost minimum of the remaining suffix must sit at the *far end* of that
///   suffix, AND every rejected `j` before it must have its disqualifying smaller element sitting
///   near that same far end too (so each rejection's `k`-scan is long, not short). The pattern
///   `[2, 3, 4, ..., n, 1]` (every value ascending except the true minimum, relocated from the
///   front to the very back) has exactly this shape, and — critically — it reproduces itself on
///   the remaining suffix after each swap (`[2,...,n,1] → [3,...,n,2] → ...`), so the *Θ*((n-i)^2)
///   cost at level `i` compounds across all `i` into a true `Σ(n-i)^2 = Θ(n^3)` total. The
///   op-counting harness confirms this: measured `k`-loop compares at `n = 8, 16, ..., 256` on this
///   exact pattern give pairwise growth-rate exponents (`log(cost ratio) / log(size ratio)`
///   between successive doublings) of `3.02, 3.00, 3.00, 3.00, 3.00` — converging tightly on the
///   cubic exponent, not merely "large." This pattern is not a contrived corner case, either: this
///   codebase's own `MovedElementShuffle` applied to an already-sorted array with `start` near `0`
///   and `dest` near `n - 1` produces exactly this shape, so the cubic worst case is one existing
///   shuffle preset away from being triggered in the running app, not a purely theoretical bound.
/// - **Average case (uniformly random input) is empirically *Θ*(*n*^2 log n)**, strictly between
///   the quadratic best/reverse-sorted cases and the cubic adversarial one. Dividing the measured
///   average `k`-loop compare count by `n^2` alone keeps climbing as `n` grows (0.68, 0.82, 0.98,
///   1.12, 1.30, 1.39, 1.46 at `n = 16, 32, ..., 512` — not converging, ruling out plain
///   *Θ*(*n*^2)), but dividing that same count by `n^2 \log_2 n` instead stabilizes tightly around
///   `0.16` across the same size range (0.170, 0.165, 0.163, 0.160, 0.162, 0.162, 0.162) — the
///   signature of a genuine extra logarithmic factor, not measurement noise.
///
/// Net effect: unlike `SlowSort`/`StoogeSort`, which are uniformly slow in every case, `BadSort`'s
/// pain is concentrated in inputs that are *far* from already sorted in a specific way — ordinary
/// randomized shuffling costs noticeably less than the cubic headline bound would suggest, but a
/// realistic non-adversarial preset (`MovedElementShuffle` on sorted input) still reaches it.
///
/// ## Stability: empirically and by hand, `false`
///
/// This is a swap-based selection sort — `engine.swap(i, shortest)` unconditionally exchanges
/// whatever currently sits at `i` with whatever sits at `shortest`, rather than shifting elements
/// between them over by one the way a stable insertion-style move would. That is the textbook
/// source of instability in ordinary (non-suffix-minimum) selection sort, and it applies here
/// unchanged: swapping the leftmost suffix minimum into position `i` can jump it *backward* past
/// one or more equal-valued elements sitting between `i` and `shortest`, and simultaneously carries
/// whatever value used to live at `i` *forward* past those same equal elements — reordering them
/// relative to each other. Hand-simulating the tagged input `[3a, 4, 3b, 2]` (values with an
/// original-order tag) confirms this concretely: `i = 0` finds `shortest = 3` (the `2`) and swaps,
/// giving `[2, 4, 3b, 3a]`; `i = 1` finds the leftmost suffix minimum of `[4, 3b, 3a]` is `3b`
/// (`shortest = 2`) and swaps, giving `[2, 3b, 4, 3a]`; `i = 2` finds the leftmost suffix minimum
/// of `[4, 3a]` is `3a` (`shortest = 3`) and swaps, giving the final `[2, 3b, 3a, 4]` — the two
/// `3`s come out in the order `3b, 3a`, the *reverse* of their `3a, 3b` input order. The standalone
/// verification harness confirms this both as this exact hand-worked case and via hundreds of
/// randomized heavily-duplicated trials (roughly 93% of trials at sizes 8–64 exhibit at least one
/// reordering), so this is **not** a stable sort.
///
/// ## Sizing
///
/// `sizeRange: 16...128` mirrors `StoogeSort`'s cap rather than `SelectionSort`'s `16...256`:
/// `StoogeSort`'s accepted worst-case tape at its own ceiling (`n = 128`) is on the order of a few
/// hundred thousand compares, and `BadSort`'s adversarial worst case at that same size
/// (`n = 128`, ~349,500 `k`-loop compares measured) is already comparable — pushing the ceiling to
/// `256` would roughly 8x that (the cubic growth measured above), so `128` errs toward the smaller,
/// already-accepted magnitude for a "deliberately slow" entry, per the batch's own guidance.
public struct BadSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "badsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bad Sort",
        category: .selection,
        sizeRange: 16...128,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n^2)", average: "O(n^2 \\log n)", worst: "O(n^3)"),
        spaceComplexity: "O(1)",
        iconName: "hand.thumbsdown.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        for i in 0..<n {
            var shortest = i
            var j = i
            while j < n {
                var isShortest = true
                var k = j + 1
                while k < n {
                    // Reads.compareValues(array[j], array[k]) == 1 — strict greater-than, both
                    // live indices (see the doc comment above for why this still goes through
                    // `engine.compare` despite ArrayV routing it through `compareValues`).
                    if engine.compare(j, k, by: (>)) {
                        isShortest = false
                        break
                    }
                    k += 1
                }
                if isShortest {
                    shortest = j
                    break
                }
                j += 1
            }
            engine.swap(i, shortest)
        }
    }
}
