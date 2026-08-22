import Foundation

/// Numerically stable running mean/variance via Welford's online algorithm — avoids storing
/// every sample just to compute a standard deviation once sampling stops.
struct RunningStatistics {
  private(set) var count = 0
  private(set) var mean = 0.0
  private var m2 = 0.0

  mutating func record(_ value: Double) {
    count += 1
    let delta = value - mean
    mean += delta / Double(count)
    let delta2 = value - mean
    m2 += delta * delta2
  }

  var variance: Double { count > 1 ? m2 / Double(count - 1) : 0 }
  var standardDeviation: Double { variance.squareRoot() }

  /// Relative standard error of the mean, `(σ/√n)/μ`. `.infinity` when the mean is (near) zero,
  /// so an all-zero sample never spuriously looks "stable."
  var relativeStandardError: Double {
    guard abs(mean) > .ulpOfOne else { return .infinity }
    return (standardDeviation / Double(count).squareRoot()) / abs(mean)
  }
}

struct AdaptiveSampleResult {
  let statistics: RunningStatistics
  /// `true` if sampling stopped because the relative standard error dropped below `tolerance`;
  /// `false` if it stopped only because `maxTrials` was reached. The calibration report surfaces
  /// this distinction — "confidently stable" reads very differently from "gave up."
  let convergedByPrecision: Bool
}

/// Sequential sampling with a relative-standard-error stopping rule: keep drawing samples until
/// the running mean is precise to within `tolerance` (default 1%), rather than a fixed trial
/// count. A fully deterministic measurement (same value every trial, e.g. an algorithm whose
/// operation count for a given `n` doesn't depend on the shuffle's specific permutation)
/// converges as soon as `minTrials` is reached, since its variance is already zero.
enum AdaptiveSampling {
  static func sample(
    tolerance: Double = 0.01, minTrials: Int = 5, maxTrials: Int = 200,
    _ nextSample: () -> Double
  ) -> AdaptiveSampleResult {
    var stats = RunningStatistics()
    for trial in 1...maxTrials {
      stats.record(nextSample())
      if trial >= minTrials, stats.relativeStandardError < tolerance {
        return AdaptiveSampleResult(statistics: stats, convergedByPrecision: true)
      }
    }
    return AdaptiveSampleResult(statistics: stats, convergedByPrecision: false)
  }
}
