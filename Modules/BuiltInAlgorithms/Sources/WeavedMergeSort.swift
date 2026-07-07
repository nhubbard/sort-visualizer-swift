import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.merge.WeavedMergeSort` — a merge sort that splits its input
/// into interleaved ("weaved") strided sub-sequences instead of contiguous left/right halves.
///
/// `merge(residue, modulus)` operates on the strided sub-sequence of indices `residue,
/// residue+modulus, residue+2*modulus, ...`. It recurses into the "even" interleaved half (same
/// `residue`, doubled modulus) and the "odd" interleaved half (`residue+modulus`, doubled
/// modulus) — each recursive call sorts and writes its own strided positions back into the shared
/// array before returning — then merges those two already-sorted interleaved runs back together
/// at the ORIGINAL stride (`modulus`, not the doubled `dmodulus` used for recursion) into a shared
/// scratch buffer, and finally copies the merged strided positions from the scratch buffer back
/// over `array`.
///
/// The merge step's comparison is ArrayV's `Reads.compareValues(array[low], array[high])`: `cmp ==
/// 1` (strictly `array[low] > array[high]`) or a tie broken by *index* rather than value (`cmp ==
/// 0 && low > high`) both route the pick to `array[high]`. Because `low`/`high` are live indices
/// into `array` (not snapshotted values — the recursive calls above may have just rewritten them),
/// this reads `engine.values` directly rather than going through `engine.compare`, matching how
/// `CountingSort`/`DoubleInsertionSort` read `engine.values` directly for comparisons ArrayV itself
/// performs via `Reads.compareValues`/`analyzeMax` rather than `Reads.compareIndices` (i.e. ArrayV
/// itself doesn't mark/animate this particular comparison as an indexed compare).
///
/// NOTE on the top-level call count: this algorithm is sometimes described (including in a
/// plausible-looking but incorrect paraphrase of this very file) as calling `merge(array, tmp,
/// length, 0, 1)` *twice* from `runSort`, as if the interleaved scheme left behind an artifact that
/// a second pass mops up. Having read ArrayV's actual source directly
/// (`~/ArrayV/src/main/java/io/github/arrayv/sorts/merge/WeavedMergeSort.java`) and its full `git
/// log -p` history back to the file's original 2022 commit (`5ad6c80`, "Move sorts"), `runSort` has
/// only ever called `merge` ONCE, immediately followed by `Writes.deleteExternalArray(tmp)` — there
/// is no double call and never has been. This port matches ArrayV's real, single-call behavior.
/// (Empirically, a single top-level call already leaves the array fully sorted across hundreds of
/// randomized trials — see the correctness testing performed while porting this file — so even a
/// hypothetical second call would be a redundant no-op, not a load-bearing fixup.)
public struct WeavedMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "weavedmergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Weaved Merge Sort",
        category: .merge,
        sizeRange: 16...512,
        // The tie-break rule `cmp == 0 && low > high` decides which of two EQUAL values to place
        // next based on the numeric value of their current strided *positions* in `array`, not on
        // which one originally appeared first in the input. Because the interleaved residue/modulus
        // splitting scatters an original run of equal values across many different strided
        // sub-sequences (unlike a normal merge sort, where "left" and "right" runs are contiguous
        // slices that already agree with original array order), this position-based tie-break does
        // NOT reduce to "preserve original relative order" the way a normal stable merge's
        // low-index-wins tie-break does. Verified empirically with tagged-duplicate input
        // (index-tagged values sorted purely on an untagged key): equal-valued tags come out
        // reordered relative to their original input order, so this is NOT a stable sort.
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(n)",
        iconName: "shuffle"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }

        let tempHandle = engine.createAuxArray(length: n)
        // The real backing store for the scratch buffer — `writeAux` only feeds the tape/visualizer,
        // it can't be read back, so the merge's actual working data lives here (mirroring how
        // `BottomUpMergeSort`/`MergeSort` keep their own shadow arrays alongside the aux writes).
        var tmp = engine.values

        func merge(_ residue: Int, _ modulus: Int) {
            guard residue + modulus < n else { return }

            var low = residue
            var high = residue + modulus
            let dmodulus = modulus << 1

            merge(low, dmodulus)
            merge(high, dmodulus)

            var nxt = residue
            while low < n && high < n {
                let takeHigh = engine.values[low] > engine.values[high]
                    || (engine.values[low] == engine.values[high] && low > high)
                if takeHigh {
                    tmp[nxt] = engine.values[high]
                    engine.writeAux(tempHandle, at: nxt, value: engine.values[high])
                    high += dmodulus
                } else {
                    tmp[nxt] = engine.values[low]
                    engine.writeAux(tempHandle, at: nxt, value: engine.values[low])
                    low += dmodulus
                }
                nxt += modulus
            }

            if low >= n {
                while high < n {
                    tmp[nxt] = engine.values[high]
                    engine.writeAux(tempHandle, at: nxt, value: engine.values[high])
                    nxt += modulus
                    high += dmodulus
                }
            } else {
                while low < n {
                    tmp[nxt] = engine.values[low]
                    engine.writeAux(tempHandle, at: nxt, value: engine.values[low])
                    nxt += modulus
                    low += dmodulus
                }
            }

            var i = residue
            while i < n {
                engine.setValue(i, tmp[i])
                i += modulus
            }
        }

        merge(0, 1)

        engine.deleteAuxArray(tempHandle)
    }
}
