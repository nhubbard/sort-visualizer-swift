import AlgorithmKit
import SortEngineKit

public struct MergeBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "mergebogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Merge Bogo Sort",
    category: .impractical,
    sizeRange: 4...10,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times 2^n)", worst: "O(n \\times 2^n)"),
    spaceComplexity: "O(n)",
    iconName: "shuffle.circle.fill"
  )
  public init() {}

  /// ArrayV's `MergeBogoSort` recursively sorts each half, then randomly "weaves" the two
  /// already-sorted runs back together by picking a random subset of positions to pull from the
  /// right run until the result is sorted. Ported as a deterministic walk instead: every bitmask
  /// of length `end - start` with exactly `end - mid` bits set is one candidate interleaving (bit
  /// set = pull from the right run); walking masks in increasing order and skipping any whose bit
  /// count doesn't match visits every interleaving exactly once, and the correct one is always
  /// among them, so termination is guaranteed.
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

    func applyWeave(_ start: Int, _ mid: Int, _ end: Int, mask: Int) {
      var low = start
      var high = mid
      for offset in 0..<(end - start) {
        let pullFromHigh = (mask >> offset) & 1 == 1
        if pullFromHigh {
          engine.setValue(start + offset, tmp[high])
          high += 1
        } else {
          engine.setValue(start + offset, tmp[low])
          low += 1
        }
      }
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

      let popcountTarget = end - mid
      var mask = -1
      while !isRangeSorted(start, end) {
        repeat { mask += 1 } while mask.nonzeroBitCount != popcountTarget
        applyWeave(start, mid, end, mask: mask)
      }
    }

    mergeBogo(0, n)

    engine.deleteAuxArray(tmpHandle)
  }
}
