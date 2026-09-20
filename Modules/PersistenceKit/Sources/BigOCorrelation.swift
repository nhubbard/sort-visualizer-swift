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
    /// The smallest total at this size — the best case actually recorded.
    case statMin
    /// The largest total at this size — the worst case actually recorded.
    case statMax
    /// The median total at this size (average of the two middle values on an even run count).
    case statMedian
    /// One of two points per size — `mean − stddev` and `mean + stddev` (clamped at 0, since a
    /// real operation count can't go negative) — bracketing the per-size average with one sample
    /// standard deviation on either side. Distinguished from one another by `id`, not by any
    /// field on the point itself; both render identically.
    case statStdDevBand
  }

  public let id: String
  public let series: String
  public let size: Int
  public let normalizedValue: Double
  public let kind: Kind
}

/// Resolves a declared complexity string to a value at `n`, going beyond `BigOShape.parse`'s
/// pure-`n` shapes for `AlgorithmMetadata` entries that reference another variable.
/// `SortSession.makeTape` always shuffles a permutation of `1...n`, which pins those "extra"
/// variables to a concrete function of `n` in this specific app:
///   - Radix sort's digit count `d` and LSD's bucket count `b`: `radix` is a hardcoded `4` in both
///     `MSDRadixSort`/`LSDRadixSort`, so `d = log₄ n` and `b = 4`.
///   - Counting/Pigeonhole/Gravity sort's value range `k`: every shuffle keeps values within
///     `~[1, n]`, so `k ≈ n` regardless of which built-in shuffle produced the array.
///   - Bingo sort's unique-value count `m` is the exception — `shuffledcubic`/`shuffledquintic`
///     resample through a skewed curve and can produce duplicates, so `m` isn't a fixed function
///     of `n`. `uniqueValueRatio` is the observed `uniqueValueCount / arraySize` average, falling
///     back to `1.0` (`m = n`) when no recorded run has that field populated yet.
private func resolvedComplexityValue(_ complexity: String, n: Double, uniqueValueRatio: Double)
  -> Double? {
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
private func mergedComplexityCases(_ timeComplexity: ComplexityBounds) -> [(
  label: String, complexity: String
)] {
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
    let joinedLabel =
      matchingLabels.count == 1 ? matchingLabels[0] : matchingLabels.joined(separator: " & ")
    let combinedLabel = joinedLabel + " Case"
    cases.append((combinedLabel, entry.complexity))
  }
  return cases
}

/// Turns raw per-run operation counts into chart-ready points: individual runs as a scatter, the
/// per-array-size average as a trendline, and the algorithm's declared best/average/worst-case
/// curves as a dashed backdrop.
///
/// The scatter and trendline are normalized by the largest *individual run's* total, not the
/// largest per-size average — normalizing by average would always anchor `1.0` to the largest
/// size recorded so far (since total work is monotonic in size), making the newest size look like
/// "the worst case yet" by construction. Anchoring on the largest individual run instead lets a
/// genuine outlier at a smaller size correctly outrank a later, larger, unremarkable run.
///
/// Reference curves stay anchored to `1.0` at the largest sampled size, since a theoretical Big-O
/// curve genuinely peaks there. Every series is normalized independently — there's no shared unit
/// between raw op counts and `n^2`/`n log n`, so only growth *shape* is comparable across them.
public func bigOChartPoints(
  for summaries: [BigORecordSnapshot],
  timeComplexity: ComplexityBounds
) -> [BigOChartPoint] {
  // A stale record with an out-of-range `arraySize` (the exact category `Tools/CloudKitCleanup`
  // exists to delete -- see its own doc comment) would otherwise become `distinctSizes`' own
  // min/max, silently stretching this chart's entire domain out to accommodate one bad point
  // instead of the real, reasonable range every other point actually occupies. Filtering here
  // means a stray bad record degrades gracefully -- either ignored outright, or (if it was one of
  // only two distinct sizes) correctly falling through to the existing "not enough data" empty
  // state below -- rather than distorting the chart for every real point alongside it.
  let summaries = summaries.filter {
    $0.arraySize > 0 && $0.arraySize <= AlgorithmMetadata.maxReasonableArraySize
  }

  var totalsBySize: [Int: [Int]] = [:]
  for summary in summaries {
    let total =
      summary.compareCount + summary.swapCount + summary.mainWriteCount
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

  // The five aggregate stats replace the raw per-run scatter as each chart's *default* view —
  // see `BigOCorrelationChart`/`BigOCorrelationDetailView` — since an algorithm with many
  // recorded runs at one size makes that scatter the dominant, cluttering mark count. `.observedRun`
  // itself is untouched above; it's still emitted for the detail view's opt-in "Show Individual
  // Runs" toggle.
  let statPoints = distinctSizes.flatMap { size -> [BigOChartPoint] in
    let totals = totalsBySize[size] ?? []
    let stats = runStatistics(for: totals)
    let lowerBand = Swift.max(stats.mean - stats.standardDeviation, 0) / maxObservedValue
    let upperBand = (stats.mean + stats.standardDeviation) / maxObservedValue
    return [
      BigOChartPoint(
        id: "stat-min-\(size)", series: "Observed", size: size,
        normalizedValue: stats.min / maxObservedValue, kind: .statMin),
      BigOChartPoint(
        id: "stat-max-\(size)", series: "Observed", size: size,
        normalizedValue: stats.max / maxObservedValue, kind: .statMax),
      BigOChartPoint(
        id: "stat-median-\(size)", series: "Observed", size: size,
        normalizedValue: stats.median / maxObservedValue, kind: .statMedian),
      BigOChartPoint(
        id: "stat-stddev-lower-\(size)", series: "Observed", size: size,
        normalizedValue: lowerBand, kind: .statStdDevBand),
      BigOChartPoint(
        id: "stat-stddev-upper-\(size)", series: "Observed", size: size,
        normalizedValue: upperBand, kind: .statStdDevBand)
    ]
  }

  let uniqueValueRatioSamples = summaries.compactMap { summary -> Double? in
    guard let uniqueValueCount = summary.uniqueValueCount, summary.arraySize > 0 else { return nil }
    return Double(uniqueValueCount) / Double(summary.arraySize)
  }
  let uniqueValueRatio =
    uniqueValueRatioSamples.isEmpty
    ? 1.0
    : uniqueValueRatioSamples.reduce(0, +) / Double(uniqueValueRatioSamples.count)

  let minSize = Double(distinctSizes[0])
  let maxSize = Double(distinctSizes[distinctSizes.count - 1])
  let sampleCount = 40
  let cases = mergedComplexityCases(timeComplexity)
  let referencePoints = cases.compactMap { label, complexity -> [BigOChartPoint]? in
    guard
      let valueAtMaxSize = resolvedComplexityValue(
        complexity, n: maxSize, uniqueValueRatio: uniqueValueRatio),
      valueAtMaxSize != 0
    else { return nil }
    return (0..<sampleCount).map { index in
      let fraction = Double(index) / Double(sampleCount - 1)
      let size = minSize + fraction * (maxSize - minSize)
      let value =
        resolvedComplexityValue(complexity, n: max(size, 1), uniqueValueRatio: uniqueValueRatio)
        ?? 0
      return BigOChartPoint(
        id: "\(label)-\(index)",
        series: label,
        size: Int(size.rounded()),
        normalizedValue: value / valueAtMaxSize,
        kind: .reference
      )
    }
  }.flatMap { $0 }

  return runPoints + trendPoints + statPoints + referencePoints
}

/// Min/max/median/mean/sample-standard-deviation over one size's raw run totals, computed
/// directly (sort + a single pass) rather than via `BuiltInAlgorithms`'s test-only streaming
/// `Statistics.swift`/Welford helper -- that solves a different problem (an online running
/// estimate during adaptive calibration sampling); here every total for a size is already fully
/// materialized in memory, so a plain batch computation is simpler and just as correct.
private func runStatistics(for totals: [Int]) -> (
  min: Double, max: Double, median: Double, mean: Double, standardDeviation: Double
) {
  let sorted = totals.sorted()
  let count = Double(sorted.count)
  let mean = Double(sorted.reduce(0, +)) / count
  let median: Double =
    sorted.count % 2 == 0
    ? Double(sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
    : Double(sorted[sorted.count / 2])
  let standardDeviation: Double =
    sorted.count > 1
    ? (sorted.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / (count - 1)).squareRoot()
    : 0
  return (
    min: Double(sorted[0]), max: Double(sorted[sorted.count - 1]), median: median, mean: mean,
    standardDeviation: standardDeviation
  )
}
