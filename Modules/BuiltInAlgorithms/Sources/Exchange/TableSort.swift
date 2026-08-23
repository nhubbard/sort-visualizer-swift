import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/TableSort` — the same median-of-three Hoare-style
/// quicksort shape as `ForcedStableQuickSort`, but it never touches the real array during
/// partitioning: it quicksorts an index permutation `table` (`table[a]`/`table[b]` stand in for
/// `array[a]`/`array[b]` in every comparison), then applies the finished permutation to `array` in
/// one final pass. `table` mirrors as an aux handle + shadow `[Int]`, same as
/// `ForcedStableQuickSort`'s `key`.
///
/// **Port decision on the final apply step:** ArrayV applies the permutation with a single held
/// temp value and a write-only cycle-follow (`Writes.write`, never `Writes.swap`) — faithful to
/// that would mean this algorithm never emits a `.swap` on the real array at all, which would make
/// the swap-tape-shadow stability fuzz test (see `NativeAlgorithmCorrectnessTests.swift`) blind to
/// this algorithm's actual behavior: the shadow would never move, so the test would trivially
/// report "stable" regardless of what `table`'s own quicksort actually did. Applying a fixed
/// permutation by walking each cycle with adjacent swaps instead of a held temp produces an
/// *identical* final array — for a cycle `(a1 -> a2 -> ... -> ak)`, `swap(a1,a2), swap(a2,a3), ...,
/// swap(a(k-1),ak)` rearranges the same k elements the same way a temp-and-shift walk would — so
/// the apply step below uses `engine.swap` in a cycle-follow-with-mark-visited loop instead. This
/// changes nothing about which permutation gets applied (and therefore nothing about whether the
/// result is stable), only how it's realized, in exchange for both a working stability test and a
/// more legible visualization of the final rearrangement.
public struct TableSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "tablesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Table Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1082, coefficients: [239639, 408.256, 0.172477],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.172477, 35.0156, -170.746], rSquared: 0.999979),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "tablecells"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let tableHandle = engine.createAuxArray(length: n)
    var table = Array(0..<n)
    for i in 0..<n {
      engine.writeAux(tableHandle, at: i, value: table[i])
    }

    // `stableComp(a, b)`: compares the real array through the permutation (`table[a]`/
    // `table[b]`), tie-breaking on `table`'s own original index order — matching ArrayV's
    // `Reads.compareIndices(array, table[a], table[b], ...)` / `Reads.compareOriginalIndices
    // (table, a, b, ...)` pair exactly. `engine.compare(table[a], table[b], ...)` highlights
    // the real array positions involved, same as ArrayV's own visualizer would.
    func stableComp(_ a: Int, _ b: Int) -> Bool {
      let ta = table[a]
      let tb = table[b]
      if engine.compare(ta, tb, by: >) { return true }
      return engine.values[ta] == engine.values[tb] && table[a] > table[b]
    }

    func swapTable(_ a: Int, _ b: Int) {
      table.swapAt(a, b)
      engine.writeAux(tableHandle, at: a, value: table[a])
      engine.writeAux(tableHandle, at: b, value: table[b])
    }

    func medianOfThree(_ a: Int, _ b: Int) {
      let m = a + (b - 1 - a) / 2
      if stableComp(a, m) {
        swapTable(a, m)
      }
      if stableComp(m, b - 1) {
        swapTable(m, b - 1)
        if stableComp(a, m) {
          return
        }
      }
      swapTable(a, m)
    }

    func partition(_ a: Int, _ b: Int, _ p: Int) -> Int {
      var i = a - 1
      var j = b
      while true {
        repeat { i += 1 } while i < j && !stableComp(i, p)
        repeat { j -= 1 } while j >= i && stableComp(j, p)
        if i < j {
          swapTable(i, j)
        } else {
          return j
        }
      }
    }

    func quickSort(_ a: Int, _ b: Int) {
      if b - a < 3 {
        if b - a == 2 && stableComp(a, a + 1) {
          swapTable(a, a + 1)
        }
        return
      }

      medianOfThree(a, b)
      let p = partition(a + 1, b, a)
      swapTable(a, p)

      quickSort(a, p)
      quickSort(p + 1, b)
    }

    quickSort(0, n)

    // Apply the finished `table` permutation to `array` — see the doc comment above for why
    // this is a swap-based cycle-follow rather than ArrayV's write+temp version.
    for i in 0..<n {
      guard table[i] != i else { continue }
      var j = i
      while table[j] != i {
        let next = table[j]
        engine.swap(j, next)
        table[j] = j
        engine.writeAux(tableHandle, at: j, value: j)
        j = next
      }
      table[j] = j
      engine.writeAux(tableHandle, at: j, value: j)
    }

    engine.deleteAuxArray(tableHandle)
  }
}
