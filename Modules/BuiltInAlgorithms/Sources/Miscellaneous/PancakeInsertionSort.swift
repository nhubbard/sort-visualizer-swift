import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `PancakeInsertionSort` — an insertion sort built entirely out of pancake
/// flips (prefix reversals), never a shift. The trick: instead of always re-establishing ascending
/// order after each insertion (which costs a shift for every element past the insertion point),
/// the sorted prefix is allowed to alternate between ascending and descending after every
/// insertion. Each step only needs to know which direction the *current* prefix runs in (`dir`) to
/// decide how to fold the new element in — and every fold is one to three whole-prefix reversals,
/// never a per-element shift.
///
/// `monoboundFw`/`monoboundBw` are a real published binary-search variant (Scandum's "monobound"
/// search) that finds an insertion point with one comparison per halving instead of the usual two.
/// `front` hand-sorts the first three elements via a small decision tree (the general insertion
/// loop starts at index 3) and reports which direction that left the prefix running in.
///
/// Every move is an `engine.reversal` (itself built from swaps) — no `setValue` anywhere — so the
/// swap-tape-shadow stability technique this codebase's other tests rely on applies validly here.
public struct PancakeInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pancakeinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pancake Insertion Sort",
    category: .miscellaneous,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 269, coefficients: [238285, 1736.27, 3.15629],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [3.15629, 38.1929, -381.408], rSquared: 1),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.up.arrow.down"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    func flip(_ i: Int) {
      engine.reversal(0, i)
    }

    // Monobound binary search for where `engine.values[valueIndex]` inserts into the ascending
    // range `[start, end)`.
    func monoboundFw(_ start: Int, _ endIn: Int, _ valueIndex: Int) -> Int {
      var end = endIn
      var top = end - start
      while top > 1 {
        let mid = top / 2
        if !engine.compare(valueIndex, end - mid, by: (>)) { end -= mid }
        top -= mid
      }
      if !engine.compare(valueIndex, end - 1, by: (>)) { return end - 1 }
      return end
    }

    // Monobound binary search for where `engine.values[valueIndex]` inserts into the descending
    // range `[start, end)`.
    func monoboundBw(_ startIn: Int, _ end: Int, _ valueIndex: Int) -> Int {
      var start = startIn
      var top = end - start
      while top > 1 {
        let mid = top / 2
        if engine.compare(start + mid, valueIndex, by: (>)) { start += mid }
        top -= mid
      }
      if engine.compare(start, valueIndex, by: (>)) { return start + 1 }
      return start
    }

    // Hand-sorts `[0, length)` for `length <= 3` via a small decision tree, returning whether the
    // result runs ascending (`true`) or descending (`false`).
    func front(_ length: Int) -> Bool {
      if length < 2 { return false }
      if engine.compare(0, 1, by: (>)) { flip(1) }
      if length > 2 {
        if engine.compare(1, 2, by: (>)) {
          if engine.compare(0, 2, by: (>)) {
            flip(1)
          } else {
            flip(2)
            flip(1)
          }
          return false
        } else {
          return true
        }
      }
      return true
    }

    var dir = front(n)

    var i = 3
    while i < n {
      if dir {
        if engine.compare(i - 1, i, by: (<=)) {
          // Already in place; the ascending prefix already ends <= the new element.
        } else if engine.compare(0, i, by: (>)) {
          flip(i - 1)
          dir.toggle()
        } else {
          let idx = monoboundFw(0, i, i)
          flip(i)
          let end = i - idx
          flip(end)
          flip(end - 1)
          dir.toggle()
        }
      } else {
        if engine.compare(i - 1, i, by: (>)) {
          // Already in place; the descending prefix already ends >= the new element.
        } else if engine.compare(0, i, by: (<=)) {
          flip(i - 1)
          dir.toggle()
        } else {
          let idx = monoboundBw(0, i, i)
          flip(i)
          let end = i - idx
          flip(end)
          flip(end - 1)
          dir.toggle()
        }
      }
      i += 1
    }

    if !dir {
      flip(n - 1)
    }
  }
}
