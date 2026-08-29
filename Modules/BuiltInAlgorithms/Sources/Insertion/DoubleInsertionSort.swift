import AlgorithmKit
import SortEngineKit

/// ArrayV's `DoubleInsertionSort` — grows its sorted region from the *middle* of the array
/// outward in both directions, rather than a single sorted prefix from one end. `left`/`right`
/// start straddling the midpoint (swapped into order via the one and only `swap` this algorithm
/// does; every other move is a single-element write). Each iteration absorbs one new element from
/// each side and inserts both into the sorted middle region.
///
/// Stability: `true`. An element captured from `right` (larger original index) shifts with a
/// non-strict `<=`/`>=` comparison, landing *after* any equal elements already resident; an
/// element captured from `left` (smaller original index) shifts with a strict `<`/`>` comparison,
/// landing *before* them. Every move is a single-element write, so equal elements never leapfrog
/// each other.
public struct DoubleInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "doubleinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Double Insertion Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 487, coefficients: [239509, 978.281, 0.998748],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.998748, 5.50024, -41.9973], rSquared: 0.999999),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "distribute.horizontal"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    insertionSort(into: &engine, start: 0, end: n)
  }

  /// Ports ArrayV's `insertionSort(array, start, end, sleep, auxwrite)`.
  private func insertionSort(into engine: inout RecordingEngine, start: Int, end: Int) {
    var left = start + (end - start) / 2 - 1
    var right = left + 1

    // Reads.compareIndices(array, left, right, ..., true) > 0 — strict, both indices live.
    if engine.compare(left, right, by: (>)) {
      engine.swap(left, right)
    }
    left -= 1
    right += 1

    while left >= start && right < end {
      // Reads.compareIndices(array, left, right, ..., true) > 0 — strict, both indices live.
      if engine.compare(left, right, by: (>)) {
        // `leftItem`/`rightItem` are captured *before* either while-loop below writes
        // anything, matching ArrayV's `leftItem = array[right]; rightItem = array[left];`
        // ordering exactly.
        let leftItem = engine.values[right]
        let rightItem = engine.values[left]

        var pos = left + 1
        // Reads.compareValues(array[pos], leftItem) <= 0 — non-strict: `leftItem` came
        // from `right` (a larger original index), so it must slide past any elements
        // already equal to it and land *after* them to stay stable.
        while pos <= right && engine.compareValue(pos, against: leftItem, by: (<=)) {
          engine.setValue(pos - 1, engine.values[pos])
          pos += 1
        }
        engine.setValue(pos - 1, leftItem)

        pos = right - 1
        // Reads.compareValues(array[pos], rightItem) >= 0 — non-strict: `rightItem` came
        // from `left` (a smaller original index), so it must slide past any elements
        // already equal to it and land *before* them to stay stable.
        while pos >= left && engine.compareValue(pos, against: rightItem, by: (>=)) {
          engine.setValue(pos + 1, engine.values[pos])
          pos -= 1
        }
        engine.setValue(pos + 1, rightItem)
      } else {
        let leftItem = engine.values[left]
        let rightItem = engine.values[right]

        var pos = left + 1
        // Strict compare (unlike the `if` branch's `<=`): `leftItem` is the smaller-or-equal of
        // the two new elements here, so it must stop before any equal elements. No `pos <= right`
        // bound check is needed — `rightItem` (>= `leftItem` in this branch) guarantees the scan
        // stops at or before `pos == right`.
        while engine.compareValue(pos, against: leftItem, by: (<)) {
          engine.setValue(pos - 1, engine.values[pos])
          pos += 1
        }
        engine.setValue(pos - 1, leftItem)

        pos = right - 1
        // Reads.compareValues(array[pos], rightItem) > 0 — strict, held value; same
        // "no explicit bound needed" reasoning as above, mirrored for the left edge.
        while engine.compareValue(pos, against: rightItem, by: (>)) {
          engine.setValue(pos + 1, engine.values[pos])
          pos -= 1
        }
        engine.setValue(pos + 1, rightItem)
      }

      left -= 1
      right += 1
    }

    // Only a single leftover element ever reaches here, and only on the `right` side
    // (odd-length ranges "waste" their extra element there).
    if right < end {
      var pos = right - 1
      let current = engine.values[right]
      // Unlike ArrayV's unguarded version, this needs an explicit `pos >= start` bound check:
      // the trailing element can be smaller than every element sorted so far (e.g. reverse-sorted
      // input), which would otherwise walk `pos` past `start` and out of bounds — ArrayV's Java
      // would throw ArrayIndexOutOfBoundsException there; a literal port would trap in Swift.
      while pos >= start && engine.compareValue(pos, against: current, by: (>)) {
        engine.setValue(pos + 1, engine.values[pos])
        pos -= 1
      }
      engine.setValue(pos + 1, current)
    }
  }
}
