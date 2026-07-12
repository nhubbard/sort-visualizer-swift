import AlgorithmKit
import Foundation

/// One plotted point in the Big-O correlation chart — either real data (one individual recorded
/// run, or the per-size average trendline through those runs) or a sample of one of the
/// algorithm's own best/average/worst-case curves (parsed from its `AlgorithmMetadata.timeComplexity`
/// via `BigOShape.parse`/`resolvedComplexityValue`), drawn as a dashed backdrop for comparison.
public struct BigOChartPoint: Identifiable, Sendable {
    /// Distinguishes what a point is *for* — deliberately not folded into `series`, since both
    /// `observedRun` and `observedTrend` share the series label `"Observed"` (one shared color in
    /// the chart legend) but need different Swift Charts mark types.
    public enum Kind: Sendable {
        /// One individual recorded run, unaveraged — plotted as a lone point (`PointMark`).
        case observedRun
        /// The per-size average of the real runs at that size — plotted as a solid line
        /// (`LineMark`), the "trendline" through the actual scatter.
        case observedTrend
        /// A sampled point on one of the algorithm's declared best/average/worst-case curves —
        /// plotted as a dashed line (`LineMark`).
        case reference
    }

    public let id: String
    public let series: String
    public let size: Int
    public let normalizedValue: Double
    public let kind: Kind
}

/// Resolves a declared complexity string to a value at `n`, going beyond `BigOShape.parse`'s
/// pure-`n` shapes for the handful of `AlgorithmMetadata` entries that reference another variable
/// — `BigOShape` deliberately stays app-agnostic (its own doc comment), but `SortSession.makeTape`
/// always shuffles a permutation of `1...n`, which pins most of those "extra" variables to a
/// concrete function of `n` in this specific app:
///   - Radix sort's digit count `d` and LSD's bucket count `b`: `radix` is a hardcoded `4` in both
///     `MSDRadixSort`/`LSDRadixSort`, never a runtime variable, so `d = log₄ n` and `b = 4`.
///   - Counting/Pigeonhole/Gravity sort's value range `k`: every shuffle keeps values within
///     `~[1, n]`, so `k ≈ n` regardless of which of the five built-in shuffles produced the array.
///   - Bingo sort's unique-value count `m` is the one exception — two of the five built-in shuffles
///     (`shuffledcubic`/`shuffledquintic`) resample through a skewed curve and can produce
///     duplicate values, so `m` isn't a fixed function of `n`. `uniqueValueRatio` is this same
///     algorithm's own observed `uniqueValueCount / arraySize` average, and the caller falls back
///     to `1.0` (i.e. `m = n`) when no recorded run has that field populated yet.
private func resolvedComplexityValue(_ complexity: String, n: Double, uniqueValueRatio: Double) -> Double? {
    if let shape = BigOShape.parse(complexity) {
        return shape.value(n: n)
    }
    guard let normalized = BigOShape.normalize(complexity) else { return nil }

    let radix = 4.0
    let digitCount = log(n) / log(radix)
    let uniqueValueCount = uniqueValueRatio * n

    switch normalized {
    case "d*n": return digitCount * n
    case "d*n+b": return digitCount * (n + radix)
    case "n+k": return n + n
    case "n*k": return n * n
    case "n+m^2": return n + uniqueValueCount * uniqueValueCount
    case "n*m": return n * uniqueValueCount
    default: return nil
    }
}

/// Groups best/average/worst case by normalized shape (`BigOShape.normalize`, already tolerant of
/// this codebase's inconsistent complexity-string formatting) so that when two or three of them are
/// really the same curve, the chart draws — and labels — one dashed line instead of stacking
/// indistinguishable duplicates in different colors. Preserves Best → Average → Worst order in the
/// combined label (e.g. `"Best & Average Case"`, or `"Best & Average & Worst Case"` when all three
/// match).
private func mergedComplexityCases(_ timeComplexity: ComplexityBounds) -> [(label: String, complexity: String)] {
    let rawCases: [(label: String, complexity: String)] = [
        ("Best", timeComplexity.best),
        ("Average", timeComplexity.average),
        ("Worst", timeComplexity.worst)
    ]
    let keys = rawCases.map { BigOShape.normalize($0.complexity) ?? $0.complexity }

    var cases: [(label: String, complexity: String)] = []
    var handledKeys: Set<String> = []
    for (index, entry) in rawCases.enumerated() {
        let key = keys[index]
        guard !handledKeys.contains(key) else { continue }
        handledKeys.insert(key)
        let matchingLabels = rawCases.indices.filter { keys[$0] == key }.map { rawCases[$0].label }
        let joinedLabel = matchingLabels.count == 1 ? matchingLabels[0] : matchingLabels.joined(separator: " & ")
        let combinedLabel = joinedLabel + " Case"
        cases.append((combinedLabel, entry.complexity))
    }
    return cases
}

/// Turns raw per-run operation counts into chart-ready points: every individual run's "total work"
/// plotted as a scatter, the per-array-size average plotted as a trendline through that scatter,
/// and the algorithm's own best/average/worst-case curves as a dashed backdrop for comparison.
///
/// The scatter and its trendline are normalized by the single largest *individual run's* total ever
/// recorded — not the largest per-size average. That distinction matters: normalizing by "largest
/// average bucket" instead would always anchor `1.0` to whichever size happens to be the largest one
/// recorded so far (since total work is monotonic in array size for essentially every algorithm),
/// making the newest/largest size look like "the worst case yet" by construction, regardless of
/// whether anything unusual actually happened. Anchoring on the largest individual run instead means
/// a genuine outlier — e.g. a pathological worst-case shuffle at a *smaller* size — can correctly
/// outrank a later, larger, but unremarkable run.
///
/// Reference curves are unaffected by that distinction: a pure theoretical Big-O curve is genuinely
/// largest at the largest sampled size, so anchoring each one to `1.0` there (as before) stays
/// correct. There's no shared unit between raw op counts and `n^2`/`n log n` etc. to begin with, so
/// every series here is normalized independently — comparing growth *shape*, not raw magnitude, is
/// the whole point. Every declared complexity renders a curve now, including the ones with a second
/// free variable in the general case (`resolvedComplexityValue` resolves those using this app's own
/// `1...n`-permutation convention) — only a string `resolvedComplexityValue` doesn't recognize at
/// all would contribute no curve.
public func bigOChartPoints(
    for summaries: [BigORecordSnapshot],
    timeComplexity: ComplexityBounds
) -> [BigOChartPoint] {
    var totalsBySize: [Int: [Int]] = [:]
    for summary in summaries {
        let total = summary.compareCount + summary.swapCount + summary.mainWriteCount
            + summary.auxWriteCount + summary.reversalCount
        totalsBySize[summary.arraySize, default: []].append(total)
    }

    guard totalsBySize.keys.count >= 2 else { return [] }

    let maxObservedValue = totalsBySize.values.flatMap { $0 }.map(Double.init).max() ?? 1

    let runPoints = totalsBySize.flatMap { size, totals in
        totals.enumerated().map { index, total in
            BigOChartPoint(
                id: "observed-run-\(size)-\(index)",
                series: "Observed",
                size: size,
                normalizedValue: Double(total) / maxObservedValue,
                kind: .observedRun
            )
        }
    }

    let distinctSizes = totalsBySize.keys.sorted()
    let trendPoints = distinctSizes.map { size -> BigOChartPoint in
        let totals = totalsBySize[size] ?? []
        let average = Double(totals.reduce(0, +)) / Double(totals.count)
        return BigOChartPoint(
            id: "observed-trend-\(size)",
            series: "Observed",
            size: size,
            normalizedValue: average / maxObservedValue,
            kind: .observedTrend
        )
    }

    let uniqueValueRatioSamples = summaries.compactMap { summary -> Double? in
        guard let uniqueValueCount = summary.uniqueValueCount, summary.arraySize > 0 else { return nil }
        return Double(uniqueValueCount) / Double(summary.arraySize)
    }
    let uniqueValueRatio = uniqueValueRatioSamples.isEmpty
        ? 1.0
        : uniqueValueRatioSamples.reduce(0, +) / Double(uniqueValueRatioSamples.count)

    let minSize = Double(distinctSizes[0])
    let maxSize = Double(distinctSizes[distinctSizes.count - 1])
    let sampleCount = 40
    let cases = mergedComplexityCases(timeComplexity)
    let referencePoints = cases.compactMap { label, complexity -> [BigOChartPoint]? in
        guard let valueAtMaxSize = resolvedComplexityValue(complexity, n: maxSize, uniqueValueRatio: uniqueValueRatio),
              valueAtMaxSize != 0 else { return nil }
        return (0..<sampleCount).map { index in
            let fraction = Double(index) / Double(sampleCount - 1)
            let size = minSize + fraction * (maxSize - minSize)
            let value = resolvedComplexityValue(complexity, n: max(size, 1), uniqueValueRatio: uniqueValueRatio) ?? 0
            return BigOChartPoint(
                id: "\(label)-\(index)",
                series: label,
                size: Int(size.rounded()),
                normalizedValue: value / valueAtMaxSize,
                kind: .reference
            )
        }
    }.flatMap { $0 }

    return runPoints + trendPoints + referencePoints
}
