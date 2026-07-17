import SortEngineKit

/// ArrayV's own taxonomy (`Sort.setCategory(...)`/`@SortMeta`/`@SortPackageMeta` across
/// `~/ArrayV/src/main/java/io/github/arrayv/sorts/`), not this app's own invention — matching it
/// means every ported algorithm files under the same category ArrayV itself assigns, including
/// cases where that disagrees with ArrayV's own physical package layout (e.g. `BogoSort.java`
/// lives in `sorts/distribute/` but is actually categorized `.impractical`). ArrayV's own
/// `"Distributive Sorts"` (a one-off misspelling of `"Distribution Sorts"` affecting exactly one
/// algorithm, `SimplisticGravitySort`) and `"Tests"` (an internal correctness check, not a real
/// sort) aren't represented here — the former files under `.distribution` when ported, correcting
/// the typo rather than perpetuating it; the latter isn't a sort at all.
///
/// `iconName` (on `AlgorithmMetadata` below) is a real SF Symbol name, resolved via
/// `CustomIconLabel` — v2 never ported Legacy's per-algorithm custom icon-image assets.
public enum AlgorithmCategory: String, Sendable, Codable, CaseIterable, Identifiable {
  case concurrent
  case distribution
  case exchange
  case hybrid
  case impractical
  case insertion
  case merge
  case miscellaneous
  case quick
  case selection

  public var id: Self { self }

  public var displayName: String {
    switch self {
    case .concurrent: "Concurrent Sorts"
    case .distribution: "Distribution Sorts"
    case .exchange: "Exchange Sorts"
    case .hybrid: "Hybrid Sorts"
    case .impractical: "Impractical Sorts"
    case .insertion: "Insertion Sorts"
    case .merge: "Merge Sorts"
    case .miscellaneous: "Miscellaneous Sorts"
    case .quick: "Quick Sorts"
    case .selection: "Selection Sorts"
    }
  }
}

/// Best/average/worst, as free-form display strings — feeds the existing `complexity.json`-style
/// content and the future Swift Charts complexity view (Phase 10).
public struct ComplexityBounds: Sendable, Codable, Equatable {
  public var best: String
  public var average: String
  public var worst: String

  public init(best: String, average: String, worst: String) {
    self.best = best
    self.average = average
    self.worst = worst
  }
}

public struct AlgorithmMetadata: Sendable, Codable, Equatable {
  public var displayName: String
  public var category: AlgorithmCategory
  /// Doubles as ArrayV's `unreasonableLimit` (`Sort.setUnreasonableLimit`): rather than warning
  /// once the chosen array size exceeds a per-algorithm threshold, `SortSession.start(size:)`
  /// unconditionally clamps into this range, so e.g. Bogo Sort's `[4, 16]` never lets a caller
  /// pick a size that would run effectively forever. No separate confirmation-dialog mechanism
  /// needed on top of it (§9 of ARCHITECTURE_V2.md).
  public var sizeRange: ClosedRange<Int>
  /// The increment the manual size stepper (and the `⌘⇧A` automation loop) moves by: 16 at a
  /// time for wide ranges (matching the global Settings default step), or the full range's
  /// width for narrow ones — e.g. Bogo Sort's `4...7` steps by 1, so every valid size stays
  /// reachable instead of only the two endpoints.
  public var sizeStep: Int {
    sizeRange.steppedSizeStep
  }
  public var stable: Bool
  public var timeComplexity: ComplexityBounds
  public var spaceComplexity: String
  public var iconName: String

  public init(
    displayName: String,
    category: AlgorithmCategory,
    sizeRange: ClosedRange<Int>,
    stable: Bool,
    timeComplexity: ComplexityBounds,
    spaceComplexity: String,
    iconName: String
  ) {
    self.displayName = displayName
    self.category = category
    self.sizeRange = sizeRange
    self.stable = stable
    self.timeComplexity = timeComplexity
    self.spaceComplexity = spaceComplexity
    self.iconName = iconName
  }
}
