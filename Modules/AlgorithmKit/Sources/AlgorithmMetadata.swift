import SortEngineKit

/// Mirrors ArrayV's own taxonomy (`Sort.setCategory(...)`/`@SortMeta`/`@SortPackageMeta` in
/// `~/ArrayV/src/main/java/io/github/arrayv/sorts/`), not an invention of this app — a ported
/// algorithm files under the same category ArrayV assigns, even where that disagrees with
/// ArrayV's own package layout (e.g. `BogoSort.java` lives in `sorts/distribute/` but is
/// categorized `.impractical`). Two ArrayV category strings aren't represented here:
/// `"Distributive Sorts"` (a one-off misspelling of `"Distribution Sorts"`, affecting only
/// `SimplisticGravitySort`) is corrected to `.distribution` on port rather than perpetuated, and
/// `"Tests"` (an internal correctness check, not a real sort) has no case at all.
///
/// `iconName` below is a real SF Symbol name resolved via `CustomIconLabel` — v2 never ported
/// Legacy's per-algorithm custom icon-image assets.
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
  /// needed on top of it (see Documentation/docs/architecture/overview.md's platform and scope decisions).
  public var sizeRange: ClosedRange<Int>
  /// The increment the manual size stepper (and the `⌘⇧A` automation loop) moves by: 16 at a
  /// time for wide ranges (matching the global Settings default step), or the full range's
  /// width for narrow ones — e.g. Bogo Sort's `4...7` steps by 1, so every valid size stays
  /// reachable instead of only the two endpoints.
  public var sizeStep: Int {
    sizeRange.steppedSizeStep
  }
  /// The real, measured operation-count growth curve for this algorithm (see
  /// `OperationGrowthModel`), used by `effectiveSizeRange(operationCap:)` to compute a live upper
  /// bound instead of trusting `sizeRange.upperBound`'s hand-picked guess.
  public var growthModel: OperationGrowthModel
  /// The growth family `Tools/GrowthModelCalibration` actually detected for this algorithm,
  /// before it got Taylor-expanded into `growthModel` — display-only metadata, nil for any
  /// algorithm `Tools/GrowthModelCalibration/apply_detected_models.py` hasn't processed yet
  /// (e.g. one just added and not yet calibrated).
  public var detectedGrowthModel: DetectedGrowthModel?
  public var stable: Bool
  public var timeComplexity: ComplexityBounds
  public var spaceComplexity: String
  public var iconName: String

  public init(
    displayName: String,
    category: AlgorithmCategory,
    sizeRange: ClosedRange<Int>,
    growthModel: OperationGrowthModel,
    detectedGrowthModel: DetectedGrowthModel? = nil,
    stable: Bool,
    timeComplexity: ComplexityBounds,
    spaceComplexity: String,
    iconName: String
  ) {
    self.displayName = displayName
    self.category = category
    self.sizeRange = sizeRange
    self.growthModel = growthModel
    self.detectedGrowthModel = detectedGrowthModel
    self.stable = stable
    self.timeComplexity = timeComplexity
    self.spaceComplexity = spaceComplexity
    self.iconName = iconName
  }

  /// A hard ceiling on `effectiveSizeRange`'s upper bound, independent of `operationCap` --
  /// `growthModel`'s fitted curve is only ever calibrated against a sampled range of real sizes
  /// (see `Tools/GrowthModelCalibration`), and an algorithm whose true cost grows in a way its
  /// recorded operation count doesn't fully capture (e.g. `CycleSort`'s O(n^2) comparisons happen
  /// via direct `engine.values` reads rather than `engine.compare`, invisible to the op-count the
  /// curve was fit against) can have that curve legitimately, non-degenerately solve to tens of
  /// thousands of elements once a user raises `recordingOperationCap` -- a real, reachable size
  /// no visualizer style renders as distinct elements anyway. Deliberately a fixed constant, not
  /// an `AppSettings` value: decoupling it from any user-adjustable dial is the whole point, since
  /// it was raising the *operation* cap that made an ordinary setting change balloon the *visual*
  /// size unexpectedly. ArrayV itself doesn't push its own showcase past comparable sizes.
  public static let maxReasonableArraySize = 8192

  /// `sizeRange.upperBound` replaced with a value computed live from `growthModel` and the
  /// current recording operation cap -- so raising or lowering that setting immediately
  /// recalculates every algorithm's real safe max, instead of using a number baked in by hand.
  /// `sizeRange.lowerBound` is untouched (a small-`n` visualization floor, unrelated to the
  /// operation cap). Also clamped to `maxReasonableArraySize` regardless of what the operation
  /// cap alone would allow -- see that constant's own doc comment for why.
  ///
  /// `growthModel.maxSafeSize` returns the raw floor of a fitted curve's root -- an arbitrary
  /// integer with no relationship to the size stepper's step (e.g. `2873`), even though every
  /// stepper/automation in the app moves in `sizeStep`-sized increments from `sizeRange.lowerBound`
  /// and would never land on that value by tapping. Rounding down to the nearest reachable step
  /// here means the displayed/selectable max is always a value a user could actually dial to one
  /// tap at a time, at the cost of a few percent of the `maxSafeSize` safety margin already built
  /// into `growthModel` -- negligible next to that margin's own slack.
  public func effectiveSizeRange(operationCap: Int) -> ClosedRange<Int> {
    let rawMaxSize = Swift.max(
      sizeRange.lowerBound,
      Swift.min(growthModel.maxSafeSize(forOperationCap: operationCap), Self.maxReasonableArraySize))
    let step = (sizeRange.lowerBound...rawMaxSize).steppedSizeStep
    let steppedMaxSize = sizeRange.lowerBound + step * ((rawMaxSize - sizeRange.lowerBound) / step)
    return sizeRange.lowerBound...steppedMaxSize
  }
}
