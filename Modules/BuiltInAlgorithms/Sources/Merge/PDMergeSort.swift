import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `PDMergeSort` ("Pattern-Defeating Merge Sort") — a natural merge sort:
/// `identifyRun` scans for each maximal run where every adjacent pair steps the same direction
/// (all non-decreasing, or all strictly decreasing), reversing a strictly-decreasing run in place
/// to make it ascending, then `findRuns` records every run's start position. The main loop
/// repeatedly merges adjacent pairs of runs (`merge`, choosing `mergeUp`/`mergeDown` by whichever
/// side needs a smaller half-sized buffer copy) and compacts the run-boundary list, until one
/// run — the whole sorted array — remains. Already-sorted input becomes a single run and never
/// enters the merge loop at all, giving this a real `O(n)` best case unlike an ordinary merge sort.
///
/// Stable by construction: `mergeUp` copies the *left* run and takes from that copy on a tie
/// (`<=`), the standard stable tie-break. `mergeDown` builds its result backward (highest index
/// first) and takes from its *right*-run copy on a tie (`>=`) — placing the right run's element
/// into the higher slot first necessarily leaves the left run's equal element in a lower (earlier)
/// slot, which is the same stable ordering from the other direction. A strictly-decreasing run
/// never contains adjacent equal elements by definition (that would have broken the streak), so
/// reversing it can't disturb any tie.
public struct PDMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pdmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pattern-Defeating Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2523, coefficients: [183052, 86.1501, 0.00296527],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [5.8005, 1.05975], rSquared: 0.998944),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.merge"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    let copiedHandle = engine.createAuxArray(length: n / 2)
    var copied = [Int](repeating: 0, count: n / 2)

    func writeCopied(_ i: Int, _ value: Int) {
      copied[i] = value
      engine.writeAux(copiedHandle, at: i, value: value)
    }

    func mergeUp(_ start: Int, _ mid: Int, _ end: Int) {
      for i in 0..<(mid - start) {
        writeCopied(i, engine.values[i + start])
      }
      var bufferPointer = 0
      var left = start
      var right = mid
      while left < right && right < end {
        // `copied[bufferPointer]` is a real re-read of the `copiedHandle`-shadowed buffer
        // (marked via `markAuxRead`), then compared against the live `right` index via
        // `engine.compareValue` — the aux-held value plays the "held value" role.
        engine.markAuxRead(copiedHandle, at: bufferPointer)
        if engine.compareValue(right, against: copied[bufferPointer], by: (>=)) {
          engine.setValue(left, copied[bufferPointer])
          bufferPointer += 1
        } else {
          engine.setValue(left, engine.values[right])
          right += 1
        }
        left += 1
      }
      while left < right {
        engine.setValue(left, copied[bufferPointer])
        bufferPointer += 1
        left += 1
      }
    }

    func mergeDown(_ start: Int, _ mid: Int, _ end: Int) {
      for i in 0..<(end - mid) {
        writeCopied(i, engine.values[i + mid])
      }
      var bufferPointer = end - mid - 1
      var left = mid - 1
      var right = end - 1
      while right > left && left >= start {
        // Same `markAuxRead` + `engine.compareValue` pairing as `mergeUp` above.
        engine.markAuxRead(copiedHandle, at: bufferPointer)
        if engine.compareValue(left, against: copied[bufferPointer], by: (<=)) {
          engine.setValue(right, copied[bufferPointer])
          bufferPointer -= 1
        } else {
          engine.setValue(right, engine.values[left])
          left -= 1
        }
        right -= 1
      }
      while right > left {
        engine.setValue(right, copied[bufferPointer])
        bufferPointer -= 1
        right -= 1
      }
    }

    func merge(_ leftStart: Int, _ rightStart: Int, _ end: Int) {
      if end - rightStart < rightStart - leftStart {
        mergeDown(leftStart, rightStart, end)
      } else {
        mergeUp(leftStart, rightStart, end)
      }
    }

    // Finds the end of the maximal run starting at `index` (every adjacent step in the same
    // direction), reversing it in place if that direction was strictly decreasing. Returns the
    // next run's start, or -1 if this was the last one.
    func identifyRun(_ indexIn: Int, _ maxIndex: Int) -> Int {
      guard indexIn < maxIndex else { return -1 }
      let startIndex = indexIn
      var index = indexIn
      let ascending = engine.compare(index, index + 1, by: (<=))
      index += 1
      while index < maxIndex {
        let stepAscending = engine.compare(index, index + 1, by: (<=))
        if stepAscending != ascending { break }
        index += 1
      }
      if !ascending {
        engine.reversal(startIndex, index)
      }
      return index >= maxIndex ? -1 : index + 1
    }

    // ArrayV allocates `runs` with this much slack deliberately: the compaction loop below can
    // structurally read one slot past the last meaningful entry right as `runCount` drops to 1
    // (that read's value is never used again once the outer loop sees `runCount <= 1`) — harmless
    // against Java's default-zeroed, over-allocated array, but a hard crash against a Swift array
    // sized to exactly the real entry count. Pad to the same capacity so that harmless over-read
    // lands on a real (if meaningless) `Int` instead of trapping.
    let runsCapacity = (n - 1) / 2 + 2
    let runsHandle = engine.createAuxArray(length: runsCapacity)
    var runs: [Int] = []
    var lastRun = 0
    while lastRun != -1 {
      runs.append(lastRun)
      engine.writeAux(runsHandle, at: runs.count - 1, value: lastRun)
      lastRun = identifyRun(lastRun, n - 1)
    }
    let realRunCount = runs.count
    while runs.count < runsCapacity { runs.append(0) }

    var runCount = realRunCount
    while runCount > 1 {
      var i = 0
      while i < runCount - 1 {
        let end = i + 2 >= runCount ? n : runs[i + 2]
        merge(runs[i], runs[i + 1], end)
        i += 2
      }

      var wi = 1
      var wj = 2
      while wi < runCount {
        runs[wi] = runs[wj]
        engine.writeAux(runsHandle, at: wi, value: runs[wj])
        wi += 1
        wj += 2
        runCount -= 1
      }
    }

    engine.deleteAuxArray(runsHandle)
    engine.deleteAuxArray(copiedHandle)
  }
}
