import AlgorithmKit
import SortEngineKit

/// A min-max heap (Atkinson et al.) sorted by repeated max-extraction. Unlike a plain binary
/// heap, alternating tree levels enforce opposite invariants — even-depth ("min") levels are
/// `<=` every descendant, odd-depth ("max") levels are `>=` every descendant — so both the
/// minimum (the root) and the maximum (one of the root's two children) are found in O(1), and
/// `downheap` has to look two levels ahead (children *and* grandchildren) to restore whichever
/// invariant applies at the level it started from.
///
/// `isMinLevel` recovers a position's level parity from its 1-based index's bit length (root is
/// index 1 → bit length 1 → min level; that pattern repeats every level going down) — ports
/// ArrayV's `Integer.numberOfLeadingZeros` trick using `Int.leadingZeroBitCount`, which gives the
/// same bit-length parity regardless of the two languages' different native integer widths.
/// `start` is dropped entirely: ArrayV's own `runSort` only ever calls this with `start = 0`, so
/// carrying the field through would just be unused generality.
///
/// Only `store_max` is ported — ArrayV's own `store_min` exists in the source but `runSort` never
/// calls it, so it isn't real behavior to reproduce.
///
/// Stability: `false` — heap extraction reorders equal elements relative to each other.
public struct MinMaxHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "minmaxheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Min-Max Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1114, coefficients: [219835, 258.857, 0.0344196],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.up.arrow.down.square"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var end = n

    func isMinLevel(_ position: Int) -> Bool {
      let index = position + 1
      let bitLength = index.bitWidth - index.leadingZeroBitCount
      return bitLength % 2 == 1
    }

    func downheap(_ start: Int) {
      var i = start
      let isGt = !isMinLevel(i)
      func beats(_ a: Int, _ b: Int) -> Bool {
        isGt ? engine.compare(a, b, by: >) : engine.compare(a, b, by: <)
      }

      var left = 2 * i + 1
      while left < end {
        let right = left + 1
        var nexti = left
        for c in [right, 2 * left + 1, 2 * left + 2, 2 * right + 1, 2 * right + 2] {
          if c >= end { break }
          if beats(c, nexti) { nexti = c }
        }
        if nexti <= right {
          if beats(nexti, i) { engine.swap(nexti, i) }
          return
        }
        guard beats(nexti, i) else { return }
        engine.swap(nexti, i)
        let parent = (nexti - 1) / 2
        if beats(parent, nexti) { engine.swap(nexti, parent) }
        i = nexti
        left = 2 * i + 1
      }
    }

    func heapify() {
      var i = (end - 1) / 2
      while i >= 0 {
        downheap(i)
        i -= 1
      }
    }

    func storeMax() {
      guard end > 1 else { return }
      var imax = 1
      if end > 2, engine.compare(imax, imax + 1, by: <) {
        imax += 1
      }
      end -= 1
      engine.swap(imax, end)
      if imax < end {
        downheap(imax)
      }
    }

    heapify()
    for _ in 0..<(n - 1) {
      storeMax()
    }
  }
}
