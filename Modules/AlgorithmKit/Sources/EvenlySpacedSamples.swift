/// `count` sizes evenly spaced across the range, always including both endpoints — for a narrow
/// range (e.g. Bogo Sort's `4...7`) this naturally yields every valid value rather than skipping
/// any, since the computed step floors to `1`.
public extension ClosedRange where Bound == Int {
    func evenlySpacedSamples(count: Int) -> [Int] {
        guard upperBound > lowerBound else { return [lowerBound] }
        let step = Swift.max(1, (upperBound - lowerBound) / (count - 1))
        var sizes = Array(Swift.stride(from: lowerBound, through: upperBound, by: step))
        if sizes.last != upperBound { sizes.append(upperBound) }
        return sizes
    }

    /// Every value reachable by stepping from `lowerBound` to `upperBound` by `step`, always
    /// including `upperBound` even when the range's width isn't an exact multiple of `step` —
    /// matches exactly what a user could reach one tap at a time on a `Stepper` using that step.
    func steppedValues(by step: Int) -> [Int] {
        guard step > 0, upperBound > lowerBound else { return [lowerBound] }
        var values = Array(Swift.stride(from: lowerBound, through: upperBound, by: step))
        if values.last != upperBound { values.append(upperBound) }
        return values
    }

    /// The increment a size stepper covering this range would move by: 16 at a time for wide
    /// ranges (matching the global Settings default step), or the full range's width for narrow
    /// ones — e.g. Bogo Sort's `4...7` steps by 1, so every valid size stays reachable instead of
    /// only the two endpoints. Backs `AlgorithmMetadata.sizeStep`.
    var steppedSizeStep: Int {
        upperBound - lowerBound >= 16 ? 16 : Swift.max(1, upperBound - lowerBound)
    }
}
