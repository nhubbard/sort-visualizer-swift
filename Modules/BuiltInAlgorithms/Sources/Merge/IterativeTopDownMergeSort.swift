import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `IterativeTopDownMergeSort` — an ordinary top-down merge sort (each merge
/// splits its range at the true midpoint, recursively), but computed level-by-level with plain
/// arithmetic instead of recursion. Starting from `subarrayCount` = the smallest power of two at
/// least `n`, each pass merges adjacent proportional slices (`n*i/subarrayCount` boundaries) and
/// halves `subarrayCount`; because the boundaries are proportional rather than fixed-width, this
/// naturally produces the same balanced split a recursive top-down merge sort would even when `n`
/// isn't a power of two — no separate fixup pass needed for the remainder, unlike
/// `BottomUpMergeSort`'s fixed-doubling-width approach.
///
/// ArrayV's own `runSortLarge` variant (rational-number arithmetic standing in for the
/// multiplication/division above, to dodge overflow at very large `n`) only triggers past
/// `length >= 1 << 15` — this app caps every algorithm's `sizeRange` at 256, so that branch is
/// unreachable here and isn't ported.
///
/// Stable by construction, not by fuzzing: the merge step only ever takes from the right run
/// (`high`) when the left run's current element compares strictly greater (`by: (>)`), so on a tie
/// it always takes from the left run first — the standard stable-merge tie-break.
public struct IterativeTopDownMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "iterativetopdownmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Iterative Top-Down Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2390, coefficients: [188980, 92.2662, 0.00294775],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [7.54425, 1.03832], rSquared: 0.999756),
    implementationComplexity: 15,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "square.stack.3d.down.forward"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    let tempHandle = engine.createAuxArray(length: n)
    var scratch = engine.values

    func merge(_ start: Int, _ mid: Int, _ end: Int) {
      var low = start
      var high = mid
      var nxt = start

      func take(from source: Int) {
        scratch[nxt] = engine.values[source]
        engine.writeAux(tempHandle, at: nxt, value: engine.values[source])
      }

      while low < mid && high < end {
        if engine.compare(low, high, by: (>)) {
          take(from: high)
          high += 1
        } else {
          take(from: low)
          low += 1
        }
        nxt += 1
      }
      if low >= mid {
        while high < end {
          take(from: high)
          high += 1
          nxt += 1
        }
      } else {
        while low < mid {
          take(from: low)
          low += 1
          nxt += 1
        }
      }

      for i in start..<end {
        engine.setValue(i, scratch[i])
      }
    }

    func ceilPowerOfTwo(_ x: Int) -> Int {
      var x = x - 1
      var i = 16
      while i > 0 {
        x |= x >> i
        i >>= 1
      }
      return x + 1
    }

    var subarrayCount = ceilPowerOfTwo(n)
    while subarrayCount > 1 {
      var i = 0
      while i < subarrayCount {
        merge(n * i / subarrayCount, n * (i + 1) / subarrayCount, n * (i + 2) / subarrayCount)
        i += 2
      }
      subarrayCount >>= 1
    }

    engine.deleteAuxArray(tempHandle)
  }
}
