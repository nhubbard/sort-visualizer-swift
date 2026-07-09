import AlgorithmKit
import Foundation

/// One plotted point in the Big-O correlation chart — either a real, averaged data point
/// (`isObserved: true`) or a sample of one of `BigOShape.referenceFamily`'s canonical curves,
/// drawn as a dashed backdrop for comparison.
public struct BigOChartPoint: Identifiable, Sendable {
    public let id: String
    public let series: String
    public let size: Int
    public let normalizedValue: Double
    public let isObserved: Bool
}

/// Turns raw per-run operation counts into chart-ready points: the real, observed "total work"
/// per array size (averaged across every run at that size, from every device signed into the same
/// iCloud account) alongside the classic Big-O reference family, all normalized to `1.0` at the
/// largest observed array size — comparing growth *shape*, not raw magnitude, is the whole point
/// (`BigORecord`'s counters have no shared unit with `n^2`/`n log n` etc. to begin with).
public func bigOChartPoints(for summaries: [BigORecordSnapshot]) -> [BigOChartPoint] {
    var totalsBySize: [Int: [Int]] = [:]
    for summary in summaries {
        let total = summary.compareCount + summary.swapCount + summary.mainWriteCount
            + summary.auxWriteCount + summary.reversalCount
        totalsBySize[summary.arraySize, default: []].append(total)
    }

    let observedBuckets = totalsBySize
        .map { size, totals in (size: size, average: Double(totals.reduce(0, +)) / Double(totals.count)) }
        .sorted { $0.size < $1.size }

    guard observedBuckets.count >= 2 else { return [] }

    let maxObservedValue = observedBuckets.map(\.average).max() ?? 1
    let observedPoints = observedBuckets.map { bucket in
        BigOChartPoint(
            id: "observed-\(bucket.size)",
            series: "Observed",
            size: bucket.size,
            normalizedValue: bucket.average / maxObservedValue,
            isObserved: true
        )
    }

    let minSize = Double(observedBuckets[0].size)
    let maxSize = Double(observedBuckets[observedBuckets.count - 1].size)
    let sampleCount = 40
    let referencePoints = BigOShape.referenceFamily.flatMap { label, shape -> [BigOChartPoint] in
        let valueAtMaxSize = shape.value(n: maxSize)
        return (0..<sampleCount).map { index in
            let fraction = Double(index) / Double(sampleCount - 1)
            let size = minSize + fraction * (maxSize - minSize)
            return BigOChartPoint(
                id: "\(label)-\(index)",
                series: label,
                size: Int(size.rounded()),
                normalizedValue: shape.value(n: max(size, 1)) / valueAtMaxSize,
                isObserved: false
            )
        }
    }

    return observedPoints + referencePoints
}
