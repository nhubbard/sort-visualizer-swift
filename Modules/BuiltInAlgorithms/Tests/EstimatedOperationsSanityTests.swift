import Testing

@testable import AlgorithmKit
@testable import BuiltInAlgorithms

/// Regression coverage for the `estimatedOperations(atSize:)` bug where a fast algorithm's
/// `growthModel` (a Taylor polynomial anchored at whatever size reaches the operation cap, often
/// far past the sizes this app actually displays) got evaluated directly at the UI's small
/// reference size and produced nonsensical results -- most visibly negative operation counts
/// (Cocktail Merge Sort: -525,476 at n=256). `AlgorithmMetadata.estimatedOperations(atSize:)` now
/// reads `detectedGrowthModel` instead; this sweeps every shipped algorithm at the app's real
/// default array size (`AppSettings.defaultArraySize`'s own default, duplicated here as a literal
/// since `BuiltInAlgorithms` doesn't depend on `SettingsKit`) to make sure that stays true as
/// algorithms are added or recalibrated.
@Suite
struct EstimatedOperationsSanityTests {
  @Test
  func noAlgorithmEstimatesNegativeOperationsAtTheDefaultArraySize() {
    let referenceSize = 256
    let negatives = AllBuiltInAlgorithms.sorts.compactMap { algorithm -> (String, Double)? in
      guard let ops = algorithm.metadata.estimatedOperations(atSize: referenceSize) else {
        return nil
      }
      return ops < 0 ? (algorithm.id.rawValue, ops) : nil
    }
    #expect(negatives.isEmpty, "negative estimates: \(negatives)")
  }
}
