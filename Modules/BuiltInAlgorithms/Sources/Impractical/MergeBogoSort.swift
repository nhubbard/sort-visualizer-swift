import AlgorithmKit
import SortEngineKit

public struct MergeBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "mergebogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Merge Bogo Sort",
    category: .impractical,
    sizeRange: 4...10,
    growthModel: OperationGrowthModel(
      anchorSize: 15, coefficients: [188543, 126003, 42104, 9379.37, 1567.06, 209.453],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .exponential, coefficients: [8.35267, 1.95092], rSquared: 0.999984),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times 2^n)", worst: "O(n \\times 2^n)"),
    spaceComplexity: "O(n)",
    iconName: "shuffle.circle.fill"
  )
  public init() {}

  /// ArrayV's `MergeBogoSort` recursively sorts each half, then randomly "weaves" the two
  /// already-sorted runs back together by picking a random subset of positions to pull from the
  /// right run until the result is sorted. Ported as a deterministic walk instead: every subset
  /// of `end - mid` positions (out of `end - start`) to pull from the right run is one candidate
  /// interleaving; walking subsets in lexicographic order visits every interleaving exactly once,
  /// and the correct one is always among them, so termination is guaranteed.
  ///
  /// Candidate interleavings are enumerated as an explicit sorted array of "pull from the right
  /// run" offsets (standard lexicographic next-combination), not as bits of a fixed-width `Int`
  /// — a 64-bit mask can't represent a merge range wider than 64 elements at all (`mask >>
  /// offset` for `offset >= 64` saturates to `0` rather than trapping, per Swift's smart-shift
  /// semantics), so the original bitmask version silently became unable to express the correct
  /// interleaving, and looped forever re-trying only representable-but-wrong ones, for any
  /// top-level array size past 64.
  ///
  /// Uses a real aux array for the pre-weave snapshot (matching `MergeSort.swift`) rather than
  /// ArrayV's reuse of the main array as scratch space.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var tmp = [Int](repeating: 0, count: n)
    let tmpHandle = engine.createAuxArray(length: n)

    func isRangeSorted(_ start: Int, _ end: Int) -> Bool {
      for i in start..<(end - 1) where engine.compare(i, i + 1, by: (>)) { return false }
      return true
    }

    func applyWeave(_ start: Int, _ mid: Int, _ end: Int, highOffsets: [Int]) {
      var low = start
      var high = mid
      var nextHighIndex = 0
      for offset in 0..<(end - start) {
        let pullFromHigh = nextHighIndex < highOffsets.count && highOffsets[nextHighIndex] == offset
        if pullFromHigh {
          engine.setValue(start + offset, tmp[high])
          high += 1
          nextHighIndex += 1
        } else {
          engine.setValue(start + offset, tmp[low])
          low += 1
        }
      }
    }

    /// Advances `combination` (a sorted array of `k` distinct offsets in `0..<width`) to the next
    /// one in lexicographic order, or returns `false` if it's already the last (`[width-k, ...,
    /// width-1]`) — the standard "next combination" algorithm: find the rightmost offset that
    /// isn't already at its maximum, bump it, then pack every offset after it back-to-back.
    func nextCombination(_ combination: inout [Int], width: Int) -> Bool {
      let k = combination.count
      guard k > 0 else { return false }
      var i = k - 1
      while i >= 0 && combination[i] == width - k + i {
        i -= 1
      }
      guard i >= 0 else { return false }
      combination[i] += 1
      for j in (i + 1)..<k {
        combination[j] = combination[i] + (j - i)
      }
      return true
    }

    func mergeBogo(_ start: Int, _ end: Int) {
      guard start < end - 1 else { return }
      let mid = (start + end) / 2
      mergeBogo(start, mid)
      mergeBogo(mid, end)

      for i in start..<end {
        tmp[i] = engine.values[i]
        engine.writeAux(tmpHandle, at: i, value: tmp[i])
      }

      let width = end - start
      let popcountTarget = end - mid
      var highOffsets = Array(0..<popcountTarget)
      var isFirstAttempt = true
      while !isRangeSorted(start, end) {
        if !isFirstAttempt {
          let advanced = nextCombination(&highOffsets, width: width)
          precondition(advanced, "every interleaving was tried without finding a sorted one")
        }
        isFirstAttempt = false
        applyWeave(start, mid, end, highOffsets: highOffsets)
      }
    }

    mergeBogo(0, n)

    engine.deleteAuxArray(tmpHandle)
  }
}
