import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/ForcedStableQuickSort` — an in-place, median-of-three
/// Hoare-style quicksort forced stable via an external `key` array (initialized `0..<n`, swapped
/// in lockstep with every real array swap via `stableSwap`). `stableComp` compares real array
/// values first; only when they're equal does it break the tie by comparing `key`'s original
/// index order, so two equal-valued elements can never cross past each other despite the in-place
/// swapping. `key` mirrors ArrayV's own `Writes.createExternalArray` visualized scratch array —
/// ported as an aux handle paired with a plain shadow `[Int]` (the same "aux handle + real local
/// array" pattern `MergeSort`/`SimplifiedLibrarySort` already use for their own scratch buffers).
/// Every real-array mutation goes through `engine.swap`, so the standard swap-tape-shadow fuzz
/// test applies directly to this one (see the dedicated stability test in
/// `NativeAlgorithmCorrectnessTests.swift`).
public struct ForcedStableQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "forcedstablequicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Forced Stable Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1060, coefficients: [239803, 409.245, 0.172442],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.172442, 43.6682, -241.159], rSquared: 0.99998),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "lock.rectangle"
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

    // `stableComp(a, b)`: true when `a` should be considered greater than `b` — real array
    // values first (a single `engine.compare`, matching ArrayV's one `Reads.compareIndices`
    // call), falling back to `key`'s original order only on a genuine value tie. The equality
    // check reads `engine.values` directly rather than issuing a second compare op, since the
    // tie-break is bookkeeping, not a user-visible comparison in its own right.
    func stableComp(_ a: Int, _ b: Int) -> Bool {
      if engine.compare(a, b, by: >) { return true }
      return engine.values[a] == engine.values[b] && key[a] > key[b]
    }

    func stableSwap(_ a: Int, _ b: Int) {
      engine.swap(a, b)
      key.swapAt(a, b)
      engine.writeAux(keyHandle, at: a, value: key[a])
      engine.writeAux(keyHandle, at: b, value: key[b])
    }

    func medianOfThree(_ a: Int, _ b: Int) {
      let m = a + (b - 1 - a) / 2
      if stableComp(a, m) {
        stableSwap(a, m)
      }
      if stableComp(m, b - 1) {
        stableSwap(m, b - 1)
        if stableComp(a, m) {
          return
        }
      }
      stableSwap(a, m)
    }

    func partition(_ a: Int, _ b: Int, _ p: Int) -> Int {
      var i = a - 1
      var j = b
      while true {
        repeat { i += 1 } while i < j && !stableComp(i, p)
        repeat { j -= 1 } while j >= i && stableComp(j, p)
        if i < j {
          stableSwap(i, j)
        } else {
          return j
        }
      }
    }

    func quickSort(_ a: Int, _ b: Int) {
      if b - a < 3 {
        if b - a == 2 && stableComp(a, a + 1) {
          stableSwap(a, a + 1)
        }
        return
      }

      medianOfThree(a, b)
      let p = partition(a + 1, b, a)
      stableSwap(a, p)

      quickSort(a, p)
      quickSort(p + 1, b)
    }

    quickSort(0, n)
    engine.deleteAuxArray(keyHandle)
  }
}
