import AlgorithmKit
import SortEngineKit

public struct SmartBogoBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "smartbogobogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Smart Bogo Bogo Sort",
    category: .impractical,
    sizeRange: 4...8,
    growthModel: OperationGrowthModel(
      anchorSize: 16, coefficients: [124301, 86878.5, 31340.6, 7737.59, 1465.42, 226.476],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "questionmark.app.fill"
  )
  public init() {}

  /// ArrayV's `SmartBogoBogoSort` recursively sorts the prefix `[0, length - 1)` first, then —
  /// while the last two elements are out of order — reshuffles the *whole* `[0, length)` range
  /// and re-sorts the prefix again. The reshuffle is the same open-ended random walk `BogoSort`
  /// already fixed elsewhere in this family.
  ///
  /// **A first port attempt substituted a lexicographic `nextPermutation` walk of the whole
  /// `[0, length)` range for the reshuffle — the same technique `LessBogoSort`/
  /// `CocktailBogoSort` use — and it was wrong.** That technique's termination guarantee relies
  /// on nothing else touching the range between successive `nextPermutation` calls, so each call
  /// provably advances to a new, never-before-seen arrangement until the exhaustive cycle
  /// necessarily reaches one that satisfies the check. Here, `smartBogoBogo(length - 1)` *does*
  /// touch that range between reshuffles — it fully re-sorts the prefix — which can undo
  /// `nextPermutation`'s progress and strand the walk in a real 2-cycle. Confirmed empirically:
  /// input `[2, 1, 1, 2]` hangs the whole array in an infinite loop, deterministically, not a
  /// rare timing fluke — found via this codebase's own duplicate-heavy fuzz coverage.
  ///
  /// The fix keeps the same recursive shape but changes what "reshuffle" means: repeatedly swap
  /// the *next* prefix position (`candidate`, starting at 0) into the last slot instead of
  /// permutation-walking the whole range. Because the prefix gets fully re-sorted ascending
  /// after every swap, position `candidate` right before its swap always holds the maximum of
  /// "every element except whatever's currently in the last slot" — and since we only ever reach
  /// candidate `k` because every prior candidate demonstrably *wasn't* the overall maximum
  /// (that's exactly why the loop kept going), removing another non-maximum from consideration
  /// can never change what the true maximum is. So the last candidate slot, `length - 2`, is
  /// *guaranteed* to land the real maximum in the last position and satisfy the check — a hard,
  /// provable ceiling of `length - 1` reshuffle attempts per recursion level, immune to
  /// duplicates, with no permutation-walk state to get disrupted by the interleaved prefix sort.
  ///
  /// This isn't a step down to a well-behaved sort in disguise: the outer recursive shape is
  /// unchanged, so the same multiplicative blowup applies — each of up to `length - 1` reshuffle
  /// attempts at one level re-triggers a full worst-case recursive call at `length - 1`, giving
  /// `T(length) = length \times T(length - 1) + O(length)`, i.e. genuinely `O(length!)` in the
  /// worst case, matching the `O(n \times n!)` this algorithm already claims and was calibrated
  /// against.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func smartBogoBogo(_ length: Int) {
      guard length > 1 else { return }
      smartBogoBogo(length - 1)
      var candidate = 0
      while engine.compare(length - 2, length - 1, by: (>)) {
        engine.swap(candidate, length - 1)
        candidate += 1
        smartBogoBogo(length - 1)
      }
    }

    smartBogoBogo(n)
  }
}
