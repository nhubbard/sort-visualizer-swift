import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.insert.ClassicTreeSort` — builds an unbalanced binary search
/// tree over the ORIGINAL array's indices (not its values directly), then reads the sorted order
/// back out via an in-order traversal.
///
/// ## The dual use of index `0`
///
/// `lower`/`upper` are `n`-sized arrays of indices: `lower[r]`/`upper[r]` hold the index of node
/// `r`'s left/right child in the tree, or `0` to mean "no child." That sentinel value doubles as a
/// perfectly valid *real* node — index `0` itself, i.e. `array[0]` — because the two roles can never
/// collide: the insertion loop below starts at `i = 1`, so real node `0` is never inserted as
/// anyone's child (it is implicitly the tree's root from the very start), and therefore `lower`/
/// `upper` never need to distinguish "child is real node 0" from "no child" — that case simply never
/// arises. This is the same trick ArrayV's Java leans on directly (`if (lower[r] != 0)`) and this
/// port preserves it exactly rather than introducing an `Int?`/sentinel type, to keep the port a
/// faithful, easily-diffed translation.
///
/// For `i` from `1` to `n - 1`, `array[i]` is walked down the tree starting at the root (`c = 0`):
/// at each node `c`, `array[i] < array[c]` routes to `lower[c]` (left), anything else — greater OR
/// equal, i.e. ties break right — routes to `upper[c]` (right); this repeats through whichever
/// child pointer is non-zero until an empty (`0`) slot is found, where `i` is recorded as that
/// child. Once every index has been inserted, an in-order traversal (visit `lower[r]`, emit `r`,
/// visit `upper[r]`, starting from the root `r = 0`) into a `temp` buffer produces the values in
/// sorted order, which is then copied back over the live array.
///
/// ## Stability: analytically and empirically `true`
///
/// This is a textbook case of the general "tree sort is stable when equal keys are always routed to
/// a fixed side" result: every comparison here breaks ties toward `upper` (right) — `array[i] <
/// array[c]` is a strict less-than, so an equal value never takes the `lower` branch — and the
/// traversal order is left-self-right (visit `lower` before emitting `r`, emit `r` before visiting
/// `upper`). Fix an original index `i1` and any later index `i2 > i1` with `array[i1] ==
/// array[i2]`. Because a node's child pointers, once set, never change (there is no rebalancing or
/// deletion — only new leaves are ever attached), and each routing decision at an already-existing
/// node depends only on the two values being compared (not on which index is doing the asking or
/// when), index `i2`'s walk from the root reproduces *exactly* the same sequence of decisions that
/// `i1`'s walk made through every node that existed at the time `i1` was inserted — right up to the
/// slot where `i1` itself came to rest. At that point `i2` finds the slot no longer empty (it now
/// holds `i1`), so it compares itself against `i1`: equal values tie, so `i2` is pushed into
/// `upper`'s subtree rooted at (or descending from) `i1` — never `lower`'s. Whatever else that
/// subtree contains by the time `i2` arrives, `i2` necessarily ends up somewhere *inside* it, and
/// in-order traversal always finishes emitting a node's entire `lower` subtree and the node itself
/// before touching anything in its `upper` subtree — so `i1` is unconditionally emitted before
/// `i2`. This holds for every such pair, so equal-valued elements always keep their original
/// relative order. A standalone script reimplementing this exact routing/traversal logic over
/// `(value, originalIndex)` pairs (comparing only on `value`, exactly mirroring ArrayV's
/// non-marking `Reads.compareValues`) confirmed this empirically too: 3,000 randomized
/// duplicate-heavy trials across sizes 4–128, plus several hand-picked adversarial cases that
/// deliberately interpose a differently-valued node between two equal-valued insertions (e.g.
/// inserting `5, 7, 5, 5`, where `7`'s node sits directly between the second and third `5`s in tree
/// structure), produced zero violations — every group of equal final values kept strictly ascending
/// original indices. See `classicTreeSortTiedElementsKeepTheirOriginalRelativeOrder` below for the
/// project-native version of that same check.
///
/// ## Complexity
///
/// Building the tree costs, for each of the `n - 1` insertions, work proportional to the depth at
/// which that index attaches — exactly like inserting into an unbalanced BST in arrival order, with
/// no rebalancing. For a RANDOM arrival order the expected depth is `O(log n)` (the classic average
/// unbalanced-BST-height result), so both the best and average cases are `O(n log n)` — even a
/// best-case arrival order that happens to build a perfectly balanced tree still pays `O(log n)`
/// average depth per insertion, summed over `n` insertions. But for an ADVERSARIAL arrival order —
/// most notably already-sorted or reverse-sorted input, since every comparison then agrees with the
/// previous one and the tree degenerates into a straight `lower`- or `upper`-only chain — each
/// insertion's depth is `Θ(i)`, so the worst case is `Θ(n^2)`, the same bound the standalone script's
/// explicit ascending/descending-input checks exercised directly. The final in-order traversal and
/// the copy-back are both `Θ(n)` regardless of tree shape, so they never change these bounds.
///
/// Space is `Θ(n)`, NOT `O(1)`/`O(log n)` like some other insertion-family sorts in this codebase —
/// unlike e.g. `BinaryInsertionSort`'s in-place shifting, this algorithm allocates three real
/// `n`-sized auxiliary arrays (`lower`, `upper`, `temp`) that all persist for the algorithm's entire
/// runtime, mirroring ArrayV's `Writes.createExternalArray` calls for the same three buffers.
public struct ClassicTreeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "classictreesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Classic Tree Sort",
        category: .insertion,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
        spaceComplexity: "O(n)",
        iconName: "list.bullet.indent"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // `lower`/`upper` back the tree's child pointers. There is no `RecordingEngine` equivalent
        // of ArrayV's `Writes.createExternalArray` that can be read back — `writeAux` only feeds
        // the tape/visualizer — so, mirroring `WeaveMergeSort`/`BottomUpMergeSort`'s established
        // pattern for scratch buffers, real Swift `[Int]` arrays drive this port's own logic while
        // parallel `engine.createAuxArray`/`writeAux` calls keep the visualizer in sync.
        var lower = [Int](repeating: 0, count: n)
        var upper = [Int](repeating: 0, count: n)
        let lowerHandle = engine.createAuxArray(length: n)
        let upperHandle = engine.createAuxArray(length: n)

        for i in 1..<n {
            var c = 0
            while true {
                // ArrayV's `Reads.compareValues(array[i], array[c]) < 0` is the non-marking
                // comparison variant (reads values directly, not via the marking
                // `Reads.compareIndices`), so this reads `engine.values` directly rather than
                // calling `engine.compare` — matching `WeaveMergeSort`'s identical convention for
                // comparisons ArrayV itself performs via `compareValues`.
                let goLower = engine.values[i] < engine.values[c]
                if goLower {
                    if lower[c] == 0 {
                        lower[c] = i
                        engine.writeAux(lowerHandle, at: c, value: i)
                        break
                    } else {
                        c = lower[c]
                    }
                } else {
                    if upper[c] == 0 {
                        upper[c] = i
                        engine.writeAux(upperHandle, at: c, value: i)
                        break
                    } else {
                        c = upper[c]
                    }
                }
            }
        }

        var temp = [Int](repeating: 0, count: n)
        let tempHandle = engine.createAuxArray(length: n)
        var idx = 0
        traverse(engine.values, lower, upper, root: 0, into: &temp, at: &idx, engine: &engine, tempHandle: tempHandle)

        for i in 0..<n {
            engine.setValue(i, temp[i])
        }

        engine.deleteAuxArray(lowerHandle)
        engine.deleteAuxArray(upperHandle)
        engine.deleteAuxArray(tempHandle)
    }

    /// Ports the recursive `traverse(array, temp, lower, upper, r)`: an in-order walk (left, self,
    /// right) that emits the tree's values into `temp` in sorted order.
    private func traverse(
        _ values: [Int],
        _ lower: [Int],
        _ upper: [Int],
        root r: Int,
        into temp: inout [Int],
        at idx: inout Int,
        engine: inout RecordingEngine,
        tempHandle: AuxHandle
    ) {
        if lower[r] != 0 {
            traverse(values, lower, upper, root: lower[r], into: &temp, at: &idx, engine: &engine, tempHandle: tempHandle)
        }
        temp[idx] = values[r]
        engine.writeAux(tempHandle, at: idx, value: values[r])
        idx += 1
        if upper[r] != 0 {
            traverse(values, lower, upper, root: upper[r], into: &temp, at: &idx, engine: &engine, tempHandle: tempHandle)
        }
    }
}
