import SortEngineKit

/// The same three groups the app already uses (`Shared/Assets.xcassets/Algorithm Icons/{Logarithmic,Quadratic,Weird}`).
public enum AlgorithmCategory: String, Sendable, Codable, CaseIterable {
    case logarithmic
    case quadratic
    case weird
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
