import AlgorithmKit
import SortEngineKit

public struct RandomGuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "randomguesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Random Guess Sort",
    category: .impractical,
    sizeRange: 4...6,
    growthModel: OperationGrowthModel(
      anchorSize: 5, coefficients: [27700.7, 68937.9, 88423.7, 77559.5, 52160.4, 28616.4],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .nToTheNLike, coefficients: [12.8644, 0.953718], rSquared: 0.999976),
    implementationComplexity: 10,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^n)", worst: "O(n^n)"),
    spaceComplexity: "O(n)",
    iconName: "questionmark.diamond.fill"
  )
  public init() {}

  /// ArrayV's `RandomGuessSort` draws each position's guess uniformly at random and checks whether
  /// the resulting mapping is sorted — same open-ended-random-walk problem `BogoSort` solved, over
  /// an `n^n` guess space. Walked here as a deterministic base-`n` odometer instead (the same fix
  /// `OptimizedGuessSort` uses) rather than drawing randomly.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var loops = [Int](repeating: 0, count: n)

    func isValidMapping() -> Bool {
      for i in 0..<(n - 1) {
        let increasing = engine.compare(loops[i], loops[i + 1], by: (<))
        engine.annotateLastOperation(
          stageID: "candidateCheck", decisionID: "randomguesssort.strictOrder",
          outcome: increasing ? "acceptPair" : "checkTie",
          roles: ["left": .arrayIndex(loops[i]), "right": .arrayIndex(loops[i + 1])],
          explanationKey: "randomguesssort.strictOrder",
          explanation: increasing
            ? "This mapped pair increases, so keep checking the candidate."
            : "This mapped pair does not increase, so check whether its values tie.")
        if increasing { continue }
        let equal = engine.compare(loops[i], loops[i + 1], by: (==))
        let stableTie = equal && loops[i] < loops[i + 1]
        engine.annotateLastOperation(
          stageID: "candidateCheck", decisionID: "randomguesssort.stableTie",
          outcome: stableTie ? "acceptPair" : "rejectCandidate",
          roles: ["left": .arrayIndex(loops[i]), "right": .arrayIndex(loops[i + 1])],
          explanationKey: "randomguesssort.stableTie",
          explanation: stableTie
            ? "Equal values retain their source order, so this mapped pair is valid."
            : "The mapped pair is descending or breaks stable tie order, so reject this candidate.")
        if stableTie { continue }
        return false
      }
      return true
    }

    while !isValidMapping() {
      for pos in 0..<n {
        if loops[pos] < n - 1 {
          loops[pos] += 1
          break
        } else {
          loops[pos] = 0
        }
      }
    }

    let mapped = loops.map { engine.readValue(at: $0) }
    for i in 0..<n {
      engine.setValue(i, mapped[i])
      engine.annotateLastOperation(
        stageID: "candidatePlacement", decisionID: "randomguesssort.candidatePlacement",
        outcome: "place", roles: ["destination": .arrayIndex(i)],
        explanationKey: "randomguesssort.candidatePlacement",
        explanation: "This candidate permutation satisfies the ordering check and is placed here.")
    }
  }
}
