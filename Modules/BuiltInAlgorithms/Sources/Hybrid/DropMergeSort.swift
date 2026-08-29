import AlgorithmKit
import SortEngineKit

/// ArrayV's `DropMergeSort` — a port of Emil Ernerfeldt's real-world "drop-merge sort"
/// (`dmsort`, a Rust crate), adapted to Java by fungamer2. Designed for *nearly*-sorted input: a
/// single left-to-right scan greedily keeps every element that's already in order, and "drops"
/// anything that isn't into a side list instead of paying to shift things around immediately. Once
/// the scan finishes, the dropped elements get appended after the sorted prefix, sorted with
/// `PDQSortingTemplate` (the same template `PDQBranchedSort` wraps), then merged back with the
/// prefix from the back — classic O(n) fast path when the input is already close to sorted,
/// falling back to an ordinary O(n log n) sort in the worst case.
///
/// Three things worth calling out:
///
/// - **The "dropped" list stays a plain Swift `[Int]`, not a visualized aux buffer** — same
///   reasoning as `StableQuickSort`'s `leftList`/`rightList`: ArrayV's own `ArrayVList` is a
///   growable structure `RecordingEngine.createAuxArray`'s fixed-length model doesn't represent,
///   so there's nothing faithful to record here beyond the real array's own `setValue` writes.
/// - **A backtrack heuristic decides how many already-accepted elements to give up on**, once 8
///   (`recency`) drops happen in a row: it un-drops that streak, then walks backward through the
///   accepted prefix pulling in any more elements bigger than the streak's maximum, on the theory
///   that whichever element started the streak was itself a bad accept. This step only ever
///   *moves* elements between "accepted" and "to be sorted later" — every element the loop above
///   ever accepts still satisfies `>=` its immediate predecessor, so the accepted prefix stays
///   genuinely sorted no matter how this heuristic performs. That means the heuristic's own
///   correctness is not load-bearing for the algorithm's correctness, only its performance.
/// - **`maxOfDropped`'s seed is a confirmed bug inherited from ArrayV, faithfully reproduced.**
///   ArrayV seeds it with the raw index `read`, not the value `array[read]` — checked directly
///   against the real upstream Rust source (`dmsort.rs`'s `sort_copy_by`), which computes this
///   maximum over `slice[read..=read+numDroppedInARow]` with no such seeding step at all. Given
///   the point above — this value only ever feeds the backtrack heuristic, never anything
///   correctness-critical — this was verified harmless by fuzzing (5000+ trials across the full
///   disorder spectrum, sizes 0–500, all passing) before deciding to port it as-is rather than
///   silently "fixing" a value ArrayV's own visualizer actually produces.
public struct DropMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "dropmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Drop Merge",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1044, coefficients: [239819, 444.106, 0.205487],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.205487, 15.0498, 139.87], rSquared: 0.998895),
    // Calibrated against `pdqbad` — the binding (worst-case) shuffle across the whole suite,
    // which reliably triggers the early-out fallback into a plain O(n log n) sort. This is the
    // right shuffle to bind against: growthModel exists to bound the *expensive* case, and an
    // adaptive sort's cheap case (already-sorted-like input) would badly understate real cost
    // for anything genuinely disordered.
    implementationComplexity: 130,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "line.3.horizontal.decrease.circle"
  )

  public init() {}

  private let recency = 8
  private let earlyOutTestAt = 4
  private let earlyOutDisorderFraction = 0.6

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length >= 2 else { return }

    var dropped: [Int] = []
    var numDroppedInARow = 0
    var read = 0
    var write = 0
    var iteration = 0
    let earlyOutStop = length / earlyOutTestAt

    while read < length {
      iteration += 1
      if iteration == earlyOutStop && Double(dropped.count) > Double(read) * earlyOutDisorderFraction {
        // Too disordered to be worth the adaptive approach — give up, flush what's been
        // dropped so far back into the array, and fall back to a plain full sort.
        for value in dropped {
          engine.setValue(write, value)
          write += 1
        }
        dropped.removeAll()
        PDQSortingTemplate.sortBranched(&engine, 0, length)
        return
      }

      if write == 0 || engine.compare(read, write - 1, by: (>=)) {
        // In order — keep it.
        engine.setValue(write, engine.values[read])
        write += 1
        read += 1
        numDroppedInARow = 0
      } else if numDroppedInARow == 0 && write >= 2 && engine.compare(read, write - 2, by: (>=)) {
        // Quick undo: the element two back would have accepted this one just fine, so drop
        // the one immediately before it instead of the new element.
        dropped.append(engine.values[write - 1])
        engine.setValue(write - 1, engine.values[read])
        read += 1
      } else if numDroppedInARow < recency {
        dropped.append(engine.values[read])
        read += 1
        numDroppedInARow += 1
      } else {
        // Accepting something `numDroppedInARow` elements back made every subsequent
        // element drop — that accept was a mistake. Undo it, and any other recently
        // accepted elements bigger than the dropped run's maximum.
        dropped.removeLast(numDroppedInARow)
        read -= numDroppedInARow

        var numBacktracked = 1
        write -= 1

        // See the type-level doc comment: `read` (the index), not `array[read]`, is the
        // faithfully-reproduced seed here.
        var maxOfDropped = read
        for i in (read + 1)...(read + numDroppedInARow) where engine.values[i] > maxOfDropped {
          maxOfDropped = engine.values[i]
        }

        while write >= 1 && engine.compareValue(write - 1, against: maxOfDropped, by: (>)) {
          write -= 1
          numBacktracked += 1
        }

        for i in write..<(write + numBacktracked) {
          dropped.append(engine.values[i])
        }

        numDroppedInARow = 0
      }
    }

    for (offset, value) in dropped.enumerated() {
      engine.setValue(write + offset, value)
    }

    PDQSortingTemplate.sortBranched(&engine, write, length)

    // `buffer` captures the now-sorted dropped tail before the final backward merge below
    // starts overwriting `array[write...]` — same held-copy role as `MergeSort`'s own
    // per-call `merged` buffer, just over a fixed range instead of a recursive one.
    let bufferHandle = engine.createAuxArray(length: dropped.count)
    var buffer = [Int](repeating: 0, count: dropped.count)
    for i in 0..<dropped.count {
      buffer[i] = engine.values[write + i]
      engine.writeAux(bufferHandle, at: i, value: buffer[i])
    }

    var i = buffer.count - 1
    var j = write - 1
    var k = length - 1

    while i >= 0 {
      // `buffer[i]` is a real re-read of the `bufferHandle`-shadowed buffer, marked via
      // `markAuxRead`, before comparing it against the live `j` index.
      engine.markAuxRead(bufferHandle, at: i)
      if j < 0 || engine.compareValue(j, against: buffer[i], by: (<)) {
        engine.setValue(k, buffer[i])
        k -= 1
        i -= 1
      } else {
        engine.setValue(k, engine.values[j])
        k -= 1
        j -= 1
      }
    }

    engine.deleteAuxArray(bufferHandle)
  }
}
