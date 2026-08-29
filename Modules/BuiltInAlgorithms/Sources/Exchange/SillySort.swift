import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/SillySort.java`, itself credited to Tom Duff (hosted at
/// `home.tiac.net/~cri_d/cri/2001/badsort.html`) — one of the classic "worse than Bogosort in
/// spirit, but fully deterministic" joke sorts.
///
/// `sillySort(i, j)` splits `[i, j]` at its midpoint `m`, recursively sorts both halves, settles
/// the smaller of the two halves' first elements (`values[i]`/`values[m+1]`) into position `i`
/// with a single compare-and-swap, and then recurses again on almost the *entire* remaining
/// range `[i+1, j]`. That shape — two half-size recursive calls plus one near-full-size
/// recursive call — is exactly `SlowSort`'s own recurrence, `T(n) = 2T(n/2) + T(n-1) + O(1)`,
/// which resolves to the same explosive `O(n^(log n))`. `sizeRange` mirrors `SlowSort.swift`'s
/// `16...64` for that reason (ArrayV assigns both the identical `unreasonableLimit(150)`, but
/// `SlowSort`'s own port found real measured blowup well before that).
public struct SillySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "sillysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Silly Sort",
    category: .exchange,
    sizeRange: 16...64,
    growthModel: OperationGrowthModel(
      anchorSize: 43, coefficients: [208617, 35618.8, 3127.73, 187.234, 8.56559, 0.318619],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .nToTheNLike, coefficients: [631.765, 0.0358603], rSquared: 0.999501),
    implementationComplexity: 5,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^{log n})", average: "O(n^{log n})", worst: "O(n^{log n})"),
    spaceComplexity: "O(log n)",
    iconName: "face.smiling.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    sillySort(&engine, 0, engine.count - 1)
  }

  private func sillySort(_ engine: inout RecordingEngine, _ i: Int, _ j: Int) {
    guard i < j else { return }
    let m = i + (j - i) / 2
    sillySort(&engine, i, m)
    sillySort(&engine, m + 1, j)
    // Engine's default comparator is `>=`, matching ArrayV's `compareValues(...) >= 0`.
    if engine.compare(i, m + 1) {
      engine.swap(i, m + 1)
    }
    sillySort(&engine, i + 1, j)
  }
}
