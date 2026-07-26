import AlgorithmKit
import SortEngineKit

public struct SnuffleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "snufflesort")
  /// `sizeRange` capped at 32: each recursion level re-snuffles overlapping halves
  /// `(stop - start + 1) / 2` times, so call count compounds faster than typical `O(n^{log n})`
  /// recursion — growth reaches ~3.4M ops by 64 and ~436M by 128 (ArrayV itself flags this
  /// `unreasonablySlow` with a limit of 100).
  public let metadata = AlgorithmMetadata(
    displayName: "Snuffle Sort",
    category: .exchange,
    sizeRange: 16...32,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^{log n})", average: "O(n^{log n})", worst: "O(n^{log n})"),
    spaceComplexity: "O(log n)",
    iconName: "pawprint.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    snuffleSort(&engine, 0, engine.count - 1)
  }

  /// Ported from ArrayV's `SnuffleSort.snuffleSort`. Compares/swaps the ends of `[start, stop]`,
  /// then for ranges of 3+ elements, recursively re-snuffles overlapping halves
  /// `[start, mid]`/`[mid, stop]` (both include `mid`) `(stop - start + 1) / 2` times.
  ///
  /// That count is a faithful port of a real quirk: the Java source's
  /// `Math.ceil((stop - start + 1) / 2)` computes the division as integer division first, so
  /// `ceil` never actually rounds anything — the real count is plain floor division, used here
  /// directly.
  private func snuffleSort(_ engine: inout RecordingEngine, _ start: Int, _ stop: Int) {
    guard stop - start + 1 >= 2 else { return }

    if engine.compare(start, stop, by: (>)) {
      engine.swap(start, stop)
    }

    if stop - start + 1 >= 3 {
      let mid = (stop - start) / 2 + start
      let iterations = (stop - start + 1) / 2
      for _ in 0..<iterations {
        snuffleSort(&engine, start, mid)
        snuffleSort(&engine, mid, stop)
      }
    }
  }
}
