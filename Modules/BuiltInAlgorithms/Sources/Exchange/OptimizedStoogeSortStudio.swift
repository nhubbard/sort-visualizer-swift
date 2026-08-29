import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/OptimizedStoogeSortStudio.java` (credited to
/// Anonymous0726's range-flagging optimizations, aphitorite's sorting-network optimizations, and
/// EilrahcF's original concept) — ArrayV's own doc comment claims this variant is both faster
/// *and* stable, running `O(n^2)` worst case / `O(n)` best case on nearly-sorted data, a real
/// complexity improvement over plain `StoogeSort`'s `O(n^2.71)`.
///
/// `stoogeSort(a, m, b, merge)` recursively partitions `[a, b)` around split points `a2`/`b2`
/// (each roughly a third of the way across), tracking whether either half changed (`lChange`/
/// `rChange`) to decide whether a follow-up "re-settle" pass is worth the extra recursive calls —
/// several of those follow-up calls intentionally discard their own returned change flag, exactly
/// as ArrayV's Java does, since only the top-level change matters for further branching.
public struct OptimizedStoogeSortStudio: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedstoogesortstudio")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Stooge Sort (Studio)",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [238710, 2185, 5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5, -5, -1.35917e-10], rSquared: 1),
    implementationComplexity: 13,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "theatermasks.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    stoogeSort(&engine, 0, 1, engine.count, false)
  }

  @discardableResult
  private func compSwap(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) -> Bool {
    if engine.compare(a, b, by: >) {
      engine.swap(a, b)
      return true
    }
    return false
  }

  @discardableResult
  private func stoogeSort(
    _ engine: inout RecordingEngine, _ a: Int, _ m: Int, _ b: Int, _ merge: Bool
  ) -> Bool {
    guard a < m else { return false }
    if b - a == 2 {
      return compSwap(&engine, a, m)
    }

    var lChange = false
    var rChange = false

    let a2 = (a + a + b) / 3
    let b2 = (a + b + b + 2) / 3

    if m < b2 {
      lChange = stoogeSort(&engine, a, m, b2, merge)
      if merge {
        rChange = stoogeSort(&engine, Swift.max(a + b2 - m, a2), b2, b, true)
        if rChange {
          stoogeSort(&engine, a + b2 - m, a2, 2 * a2 - a, true)
        }
      } else {
        rChange = stoogeSort(&engine, a2, b2, b, false)
        if rChange {
          stoogeSort(&engine, a, a2, 2 * a2 - a, true)
        }
      }
    } else {
      rChange = stoogeSort(&engine, a2, m, b, merge)
      if rChange {
        stoogeSort(&engine, a, a2, a2 + b - m, true)
      }
    }
    return lChange || rChange
  }
}
