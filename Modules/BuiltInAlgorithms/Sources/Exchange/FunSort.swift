import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/FunSort` — "Fun Sort, or the chaos of unordered binary
/// search" (fungamer2, 2020; https://www.sciencedirect.com/science/article/pii/S0166218X04001131).
/// The core idea: for each `i` from 1, repeatedly binary-search the *whole* array for where
/// `array[i]` belongs, treating it as sorted even though it generally isn't yet — a "chaotic"
/// search that nonetheless converges given enough repetition — then swap `i` toward the found
/// position and search again, until `i` reaches a fixed point.
///
/// **Not ported as a literal translation** — see Documentation/docs/architecture/content.md's note
/// on this algorithm, and this doc comment's continuation below for the two real defects a literal
/// port would carry over, fixed here instead:
///
/// 1. ArrayV's own convergence check is `Reads.compareIndices(array, pos, i, ...) != 0` — a plain
///    *value* comparison. On duplicate-heavy input, landing on any index holding a value equal to
///    `array[i]` is treated as "done," even when that index isn't `i`'s own eventual home and
///    nothing was ever moved there. Confirmed via a faithful Python re-implementation: ~87% of
///    randomized duplicate-heavy trials end genuinely unsorted, not merely unstable.
/// 2. Independent of duplicates, ArrayV's own swap rule has a silent no-op case: when the found
///    position is exactly `i + 1`, neither `i < pos - 1` nor `i > pos` holds, so nothing swaps —
///    yet the loop would keep re-searching the identical, unchanged array forever if it ever
///    reached that state with truly distinct values. This never surfaced in ArrayV's own testing
///    because defect #1's premature "done" always fired first; fixing #1 exposes #2 as a real
///    infinite loop unless it's also handled.
///
/// **The fix**: compare elements by a tie-free composite key of `(value, originalIndex)` instead
/// of value alone (via a `key` array mirroring ArrayV's own `Writes.createExternalArray`
/// convention, exactly as `ForcedStableQuickSort`/`TableSort` already do). With ties eliminated,
/// "the search finds `i` itself" becomes a well-defined fixed point, replacing the value-equality
/// shortcut — fixing defect #1. The `pos == i + 1` gap case now gets an explicit forced swap
/// instead of a no-op, guaranteeing every non-fixed-point search makes real progress — fixing
/// defect #2. Tie-breaking by original index also makes this genuinely stable, as a side effect of
/// the same fix (equal-valued elements can never compare as "equal," so their relative order is
/// always preserved). Validated by fuzzing this exact design (Python prototype) across ~7,700
/// randomized trials — duplicate-heavy and all-distinct, sizes 2 through 256, plus adversarial
/// inputs (already-sorted, reverse-sorted, all-equal) — with zero incorrect results, zero
/// non-termination, and zero instability.
public struct FunSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "funsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Fun Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 147, coefficients: [238858, 3492.7, 13.6561],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [5.24161, 2.14951], rSquared: 0.999985),
    implementationComplexity: 14,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n^2 log n)", worst: "O(n^2 log n)"),
    spaceComplexity: "O(n)",
    iconName: "shuffle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let keyHandle = engine.createAuxArray(length: n)
    var key = Array(0..<n)
    for i in 0..<n {
      engine.writeAux(keyHandle, at: i, value: key[i])
    }

    // True when the element at `mid` sorts strictly before the element at `i` under the
    // tie-free `(value, key)` composite order. The value half is a real `engine.compare` (matching
    // ArrayV's own `Reads.compareValues` call inside `binarySearch`); the key half is a raw read,
    // matching the tie-break convention `ForcedStableQuickSort`/`TableSort` already established.
    func compositeLess(_ mid: Int, _ i: Int) -> Bool {
      if engine.compare(mid, i, by: <) { return true }
      return engine.values[mid] == engine.values[i] && key[mid] < key[i]
    }

    // Lower-bound binary search across `[0, n - 1)` for where `i`'s element belongs, treating the
    // (generally not-yet-sorted) array as if it already were — matching ArrayV's own search bound
    // of `length - 1`, not `length`.
    func binarySearch(_ i: Int) -> Int {
      var start = 0
      var end = n - 1
      while start < end {
        let mid = (start + end) / 2
        if compositeLess(mid, i) {
          start = mid + 1
        } else {
          end = mid
        }
      }
      return start
    }

    func stableSwap(_ a: Int, _ b: Int) {
      engine.swap(a, b)
      key.swapAt(a, b)
      engine.writeAux(keyHandle, at: a, value: key[a])
      engine.writeAux(keyHandle, at: b, value: key[b])
    }

    for i in 1..<n {
      var done = false
      while !done {
        let pos = binarySearch(i)
        if pos == i {
          done = true
        } else if i < pos - 1 {
          stableSwap(i, pos - 1)
        } else {
          // Covers both `i > pos` (ArrayV's own second case) and the `pos == i + 1` gap ArrayV
          // silently left as a no-op — see the doc comment above for why this one must swap too.
          stableSwap(i, pos)
        }
      }
    }

    engine.deleteAuxArray(keyHandle)
  }
}
