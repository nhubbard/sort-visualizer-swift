import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.select.TriangularHeapSort` — the same extract-max heapsort
/// shape as `MaxHeapSort.swift` (build a heap bottom-up, then repeatedly swap the root to the end
/// of the shrinking heap and re-sift), but with the array's implicit tree read as a *triangular*
/// structure instead of an ordinary binary one.
///
/// ## Triangular indexing vs. the ordinary binary-heap formula
///
/// `MaxHeapSort` gives node `root` two DISJOINT children at `2*root+1`/`2*root+2` — the classic
/// binary-heap layout, where every node past the halfway point of the array is a leaf. This
/// variant instead imagines the array laid out as a triangle: row `r` (0-indexed) starts at the
/// triangular number `T(r) = r*(r+1)/2` and holds `r + 1` elements, so row 0 has 1 element, row 1
/// has 2, row 2 has 3, and so on, with each row one element wider than the last. `triangularRoot`
/// below is `T`'s inverse — given a flat array index, it returns which row that index falls in
/// (the largest `r` with `T(r) <= index`) — and a node at flat index `root` sitting at offset `p`
/// within its row (`p = root - T(r)`) has its two children at offset `p`/`p + 1` within the NEXT
/// row down, i.e. flat indices `root + r + 1` and `root + r + 2`. Unlike the binary heap's
/// disjoint children, adjacent nodes in the same row *share* a child with their neighbor (node at
/// offset `p`'s right child, offset `p + 1` in the next row, is the same slot as offset `p + 1`'s
/// left child) — the same overlapping adjacency Pascal's triangle has between rows. Hand-tracing
/// the first few rows confirms the formula: row 0 is just index 0 (`r = 0`, children at
/// `0 + 0 + 1 = 1` and `2`, i.e. all of row 1); row 1 is indices 1–2 (`r = 1`, e.g. index 1's
/// children are `1 + 1 + 1 = 3` and `4`, the first two slots of row 2); row 2 is indices 3–5, and
/// so on.
///
/// `siftDown` below otherwise follows `MaxHeapSort.swift`'s exact nested-loop shape: find the
/// larger of `root` and its (up to two) triangular children via sequential pairwise
/// `engine.compare` calls, and if a child beats the current root, `engine.swap` it up and descend;
/// otherwise stop. This is a direct (if less write-minimal) translation of ArrayV's own
/// `siftDown`, which caches the sifting value in a local `temp` and defers a single `Writes.write`
/// until the resting position is found — `MaxHeapSort.swift` already made the same simplification
/// for the ordinary binary case (full `swap`s in place of a cached temp plus one deferred write),
/// and the two are behaviorally identical: after `engine.swap(root, largest)`, the value now
/// sitting at the new `root` is exactly the value that keeps sifting down, so the very next
/// iteration's compare against "the current root's value" is the same comparison ArrayV performs
/// against its cached `temp`.
///
/// ## Why `runSort` needs an explicit final pair-swap that `MaxHeapSort` doesn't
///
/// Every extract-max heapsort's main loop only correctly places the elements it explicitly
/// swaps to the boundary of the shrinking heap and re-sifts. Once the heap has shrunk to exactly 2
/// elements (indices 0 and 1) and been re-sifted, the max-heap invariant guarantees
/// `array[0] >= array[1]` — that is, the *last two* elements are left in max-first (descending)
/// order, not ascending sorted order, because neither of them has actually been "extracted" to a
/// boundary yet.
///
/// `MaxHeapSort`'s loop bound (`while end > 0`) happens to include one further, otherwise-vacuous
/// iteration beyond that point: when `end == 1`, it does `swap(0, 1)` (which, relying on the very
/// invariant above, is exactly the corrective swap needed) followed by `siftDown(0, 1)`, which is
/// a harmless no-op on a single-element "heap." So `MaxHeapSort` never needs a special case — the
/// fix is folded into the ordinary loop as its last pass.
///
/// ArrayV's `TriangularHeapSort.runSort`, by contrast, is written with the loop bound `i < length
/// - 1` — one iteration short of that vacuous final pass (the loop's last real iteration re-sifts
/// the heap down to size 2 and stops there, never taking the `swap(0, 1)` step). This is purely an
/// implementation/loop-bound choice in the ArrayV source, not a structural necessity of the
/// triangular indexing itself (the same "stop one short, then explicit swap" restructuring could
/// equally be written for the binary case, and vice versa) — but this port must match the ground
/// truth, so the corrective swap is written out explicitly after the loop: `if array[0] >
/// array[1] { swap(0, 1) }`, using ArrayV's own non-marking `Reads.compareValues` (hence reading
/// `engine.values` directly below rather than calling `engine.compare`, matching
/// `WeaveMergeSort`'s identical convention for comparisons ArrayV performs via `compareValues`
/// rather than `compareIndices`). This restructuring is also what makes `length == 2` work
/// correctly as a base case: `runSort`'s loop (`1..<(length - 1)`, i.e. `1..<1`) never executes at
/// all for `length == 2`, so the whole sort reduces to one heapify call (which, for a 2-element
/// heap, already establishes `array[0] >= array[1]` via a single `siftDown`) followed directly by
/// this same explicit tidy-up swap.
///
/// ## Stability: empirically `false`
///
/// Like `MaxHeapSort` (documented `stable: false`), every reordering here is a plain `engine.swap`
/// driven purely by "is this child strictly greater than the current root" — ties (`==`) never
/// trigger a swap in `siftDown`, but that alone does not make swap-based heap extraction stable:
/// the heap-construction phase and the repeated root-to-boundary extraction can still relocate one
/// of two equal elements past the other with no way to recover their original relative order,
/// exactly as it does for the ordinary binary heap. Verified empirically, mirroring every other
/// port in this codebase that lacks a clean hand-provable invariant: recording tagged-duplicate
/// input (values combined with an original-index tag, comparing purely on the untagged key) across
/// many randomized trials with heavy duplication shows tagged duplicates do come out reordered
/// relative to their original input order — see the standalone verification script referenced in
/// the port notes, and
/// `NativeAlgorithmCorrectnessTests.triangularHeapSortTiedElementsCanLoseTheirOriginalRelativeOrder`
/// for the in-repo regression test.
///
/// ## Complexity: same `O(n log n)` family as `MaxHeapSort`, not degraded by the triangular shape
///
/// Row `r` of the triangular structure holds `r + 1` elements, so the total element count through
/// row `r` is `T(r + 1) = (r + 1)(r + 2)/2` — quadratic in `r` — meaning the number of rows (the
/// heap's height) needed to hold `n` elements is `O(sqrt(n))`, NOT `O(log n)` the way a binary
/// heap's height is. That looks alarming at first, but each `siftDown` call's cost is NOT
/// proportional to the height in the usual "branching factor is fixed, so cost = height" sense —
/// it is bounded by how many rows a single value can descend, and each row-to-row step here is
/// still exactly one comparison-and-possible-swap, same as a binary heap's level-to-level step. The
/// real question is how many *elements* a full `siftDown` call can touch in the worst case: from
/// row `r` (which has `r + 1` slots) descending toward the bottom row `R` (which has `R + 1`
/// slots, `R = O(sqrt(n))`), the number of rows crossed is at most `R - r = O(sqrt(n))` — so a
/// naive bound would give `O(sqrt(n))` per `siftDown`, not `O(log n)`. However, `heapify`'s bottom-
/// up construction calls `siftDown` once per starting row, and (exactly as with the binary-heap
/// proof that heapify is `O(n)` overall, not `O(n log n)`) the vast majority of starting rows are
/// near the bottom, where the remaining descent distance is tiny — the sum of "rows available to
/// descend through" across all `n` starting positions telescopes to `O(n)` total work for the
/// heapify phase either way. The `n` extraction passes in `runSort`, though, each restart a
/// `siftDown` from the *root* (row 0) every time, so each of those `n` calls genuinely can cross up
/// to `O(sqrt(current heap's row count)) = O(sqrt(n))` rows — giving `Θ(n * sqrt(n))` for the
/// extraction phase. That is worse than `MaxHeapSort`'s `Θ(n log n)` extraction phase, and dominates
/// the `O(n)` heapify phase, so **the honest worst-case bound for this algorithm's extraction-
/// dominated total work is `Θ(n * sqrt(n))`, not `Θ(n log n)`** — despite ArrayV's own class
/// comment (and the "Selection Sorts" bucket it shares with `MaxHeapSort`) implying heapsort-style
/// `O(n log n)` parity. This is called out explicitly here because the temptation is to assume
/// "it's a heap, so it's `n log n`" without re-deriving the branching factor for a genuinely
/// different node-degree structure — the row-vs-index relationship, not the two-children-per-node
/// shape, is what drives asymptotic heap-height, and this port's `sizeRange` (capped at 256, like
/// every other algorithm in this codebase) keeps the practical difference from `MaxHeapSort`
/// small, but the honest asymptotic bound is `Θ(n^1.5)`, and this type's `timeComplexity` reflects
/// that rather than `MaxHeapSort`'s `O(n log n)`.
///
/// ## A future shuffle port will need to replicate `triangularHeapify`
///
/// `PORT_INVENTORY.md`'s `TRI_HEAP` ("Triangular Heapified") shuffle calls directly into this
/// sort's own `triangularHeapify` step in ArrayV. Structs in this codebase don't expose reusable
/// methods across files for algorithms (`RecordingEngine`-driven logic lives in nested functions
/// private to each `record(into:)`), so `HeapifiedShuffle.swift` — the shuffle for the ordinary
/// binary `MaxHeapSort` — handles this by duplicating `MaxHeapSort`'s exact build-heap phase
/// inline rather than calling into `MaxHeapSort.swift` directly. A future `TriangularHeapedShuffle`
/// will need the same treatment: duplicate `triangularRoot`, `siftDown`, and the `triangularHeapify`
/// loop below verbatim (stopping short of `runSort`'s extraction/tidy-up phase, leaving the array a
/// valid triangular max-heap rather than fully sorted), keeping the method shapes/names matching
/// this file so the two stay easy to compare side by side.
public struct TriangularHeapSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "triangularheapsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Triangular Heap Sort",
        category: .selection,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n^1.5)", average: "O(n^1.5)", worst: "O(n^1.5)"),
        spaceComplexity: "O(1)",
        iconName: "triangle.fill"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // The largest row index `r` such that the triangular number `T(r) = r*(r+1)/2` is `<=
        // val` — the inverse of `T`, telling us which row of the implicit triangular tree a flat
        // array index falls in. Ports ArrayV's `triangularRoot(val)`:
        // `((int) Math.sqrt(8 * val + 1) - 1) / 2`. `val` stays well within `Double`'s exact-
        // integer range for every size this codebase allows (max array size 256, so `8 * val + 1`
        // never exceeds a few thousand), so the `Double` round-trip through `squareRoot()` never
        // loses precision the way it might for astronomically large inputs.
        func triangularRoot(_ val: Int) -> Int {
            let integerSqrt = Int(Double(8 * val + 1).squareRoot())
            return (integerSqrt - 1) / 2
        }

        // Same nested-loop shape as `MaxHeapSort.swift`'s `siftDown`, with the two DISJOINT
        // binary-heap children (`2*root+1`/`2*root+2`) replaced by this variant's triangular
        // children (`root + row + 1`/`root + row + 2`, where `row = triangularRoot(root)`).
        func siftDown(_ root: Int, _ size: Int) {
            var root = root
            while true {
                let row = triangularRoot(root)
                let left = root + row + 1
                if left >= size { break }
                let right = left + 1
                var largest = root
                if !engine.compare(largest, left) {
                    largest = left
                }
                if right < size && !engine.compare(largest, right) {
                    largest = right
                }
                if largest == root { break }
                engine.swap(root, largest)
                root = largest
            }
        }

        // Ports `triangularHeapify` — every index from `length - 1` down to `0`, unlike
        // `MaxHeapSort`'s leaf-skipping `n / 2 - 1` starting point: the triangular leaf boundary
        // isn't a single fixed fraction of `n` the way a binary heap's is, and ArrayV's own source
        // doesn't bother computing it either, so a `siftDown` call on an already-leaf index is a
        // harmless one-comparison-free no-op (`left >= size` breaks immediately) rather than an
        // optimization worth reproducing here.
        func triangularHeapify(_ length: Int) {
            var i = length - 1
            while i >= 0 {
                siftDown(i, length)
                i -= 1
            }
        }

        triangularHeapify(n)
        var i = 1
        while i < n - 1 {
            engine.swap(0, n - i)
            siftDown(0, n - i)
            i += 1
        }
        // The explicit tidy-up `MaxHeapSort` doesn't need — see the doc comment above. ArrayV
        // performs this via the non-marking `Reads.compareValues`, so this reads `engine.values`
        // directly rather than calling `engine.compare`.
        if engine.values[0] > engine.values[1] {
            engine.swap(0, 1)
        }
    }
}
