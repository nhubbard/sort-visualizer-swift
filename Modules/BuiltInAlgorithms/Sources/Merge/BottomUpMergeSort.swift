import AlgorithmKit
import SortEngineKit

/// The non-recursive twin of `MergeSort`: iterates over doubling merge-run widths (`mergeSize` =
/// 2, 4, 8, ...), merging every adjacent pair of runs of that width in one pass into a scratch
/// buffer before copying back and doubling again.
///
/// `merge`'s `copyLength` return value handles the final partial run: when the "right" half is
/// empty (only possible on a pass's last chunk), no writes happen and `index` is returned as the
/// point past which the scratch buffer shouldn't be copied back — the untouched tail is already
/// correctly ordered from the previous pass. One extra fixup merge runs after the main loop
/// whenever `n` isn't a power of two, folding the final undersized run into the rest of the array.
public struct BottomUpMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bottomupmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bottom-up Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2239, coefficients: [189030, 101.593, 0.00429632],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [6.19882, 1.0737], rSquared: 0.998405),
    implementationComplexity: 16,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "rectangle.stack"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }
    let tempHandle = engine.createAuxArray(length: n)
    // The real backing store for the scratch buffer — `writeAux` only feeds the tape/visualizer,
    // it can't be read back, so the merge's actual working data lives here (mirroring how
    // MergeSort.swift keeps its own `merged` array alongside the aux writes).
    var scratch = engine.values

    // Merges the two runs of length `mergeSize / 2` starting at `index` into `scratch`. Returns
    // a "copy up to here" override only when the right run is empty; nil means copy the whole
    // scratch buffer back once the pass finishes.
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

    var mergeSize = 2
    while mergeSize <= n {
      var copyLength = n
      var i = 0
      while i < n {
        if let override = merge(i, mergeSize) {
          copyLength = override
        }
        i += mergeSize
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
