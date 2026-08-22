import AlgorithmKit
import SortEngineKit

/// ArrayV's `CocktailMergeSort` — splices Cocktail Shaker Sort into TimSort's run-building step:
/// each fixed-size chunk (length `minRunLen`, TimSort's minrun) is sorted with Cocktail Shaker,
/// then runs are merged the way TimSort does.
///
/// Simplified from ArrayV: the galloping TimSort merge is replaced with a plain bottom-up pairwise
/// merge (same technique as `BottomUpMergeSort`, just starting from run width `minRunLen` instead
/// of `1`). Both merge strategies use the same stable take-the-left-run-on-ties comparison, so the
/// sorted output and stability are identical — only comparison count differs.
///
/// Complexity: `O(n log n)` best/average. Worst case is quoted as `O(n^2)`, not a clean `O(n log
/// n)`, because at this app's small sizes `n` and `minRunLen` usually coincide, so the whole sort
/// degenerates to plain Cocktail Shaker Sort's own quadratic worst case.
public struct CocktailMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "cocktailmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Cocktail Merge Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 756, coefficients: [239683, 1763.36, 6.48657, 0.0159073, 2.92578e-05, 4.30503e-08],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.merge"
  )
  public init() {}

  /// TimSort's "minimum run length" calculation: right-shift `n` until under 64, folding back any
  /// shifted-out 1-bit, to keep run counts balanced. For `n < 64` this just returns `n`.
  static func minRunLength(_ n: Int) -> Int {
    var n = n
    var r = 0
    while n >= 64 {
      r |= n & 1
      n >>= 1
    }
    return n + r
  }

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let minRunLen = Self.minRunLength(n)

    // Cocktail Shaker Sort, restricted to the half-open range [start, end) — CocktailShakerSort.swift's
    // logic with every index shifted to be `start`-relative and bounded by the chunk's own
    // length instead of the whole array's.
    func cocktailShaker(_ start: Int, _ end: Int) {
      let length = end - start
      guard length > 1 else { return }

      var i = 0
      while i < length / 2 {
        var sorted = true

        // Strict `>` (not the default `>=`) — matches ArrayV's real `Reads.compareValues`
        // condition, which never swaps on a tie; see `CocktailShakerSort.swift`.
        var j = i
        while j < length - i - 1 {
          if engine.compare(start + j, start + j + 1, by: (>)) {
            engine.swap(start + j, start + j + 1)
            sorted = false
          }
          j += 1
        }

        j = length - i - 1
        while j > i {
          if engine.compare(start + j - 1, start + j, by: (>)) {
            engine.swap(start + j - 1, start + j)
            sorted = false
          }
          j -= 1
        }

        if sorted { break }
        i += 1
      }
    }

    // ArrayV special-cases sortLength == minRunLen: there'd only be a single run, so building
    // it and then "merging" it alone would be a no-op wrapped around plain Cocktail Shaker Sort.
    guard n != minRunLen else {
      cocktailShaker(0, n)
      return
    }

    // Build fixed-length (minRunLen) runs, Cocktail-Shaker-sorting each in place. The final
    // chunk is shorter than minRunLen whenever minRunLen doesn't evenly divide n.
    var i = 0
    while i <= n - minRunLen {
      cocktailShaker(i, i + minRunLen)
      i += minRunLen
    }
    if i < n {
      cocktailShaker(i, n)
    }

    // Simplified TimSort merge phase: a standard bottom-up pairwise merge (see the type's doc
    // comment above for why this is a correctness-preserving stand-in for ArrayV's galloping
    // TimSort merge), structured exactly like `BottomUpMergeSort.swift`'s own `merge` helper,
    // except the initial atomic run width is `minRunLen` (from Cocktail Shaker, above) instead
    // of 1, so the doubling sequence of merge widths starts at `2 * minRunLen` instead of `2`.
    let tempHandle = engine.createAuxArray(length: n)
    var scratch = engine.values

    @discardableResult
    func merge(_ index: Int, _ mergeSize: Int) -> Int? {
      let mid = index + mergeSize / 2
      let end = min(n, index + mergeSize)

      guard mid < end else {
        return index
      }

      var left = index
      var right = mid
      var scratchIndex = index

      while left < mid && right < end {
        if engine.compare(right, left) {
          scratch[scratchIndex] = engine.values[left]
          engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[left])
          left += 1
        } else {
          scratch[scratchIndex] = engine.values[right]
          engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[right])
          right += 1
        }
        scratchIndex += 1
      }
      while left < mid {
        scratch[scratchIndex] = engine.values[left]
        engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[left])
        left += 1
        scratchIndex += 1
      }
      while right < end {
        scratch[scratchIndex] = engine.values[right]
        engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[right])
        right += 1
        scratchIndex += 1
      }
      return nil
    }

    var mergeSize = minRunLen * 2
    while mergeSize <= n {
      var copyLength = n
      var idx = 0
      while idx < n {
        if let override = merge(idx, mergeSize) {
          copyLength = override
        }
        idx += mergeSize
      }
      for j in 0..<copyLength {
        engine.setValue(j, scratch[j])
      }
      mergeSize *= 2
    }
    if mergeSize / 2 != n {
      var copyLength = n
      if let override = merge(0, mergeSize) {
        copyLength = override
      }
      for j in 0..<copyLength {
        engine.setValue(j, scratch[j])
      }
    }

    engine.deleteAuxArray(tempHandle)
  }
}
