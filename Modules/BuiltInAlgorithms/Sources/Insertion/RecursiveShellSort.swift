import AlgorithmKit
import SortEngineKit

public struct RecursiveShellSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "recursiveshellsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Recursive Shell Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 905, coefficients: [239558, 478.568, 0.235672],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.235672, 52.0013, -524.469], rSquared: 0.999937),
    implementationComplexity: 8,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n^{1.25})", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "shell.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `gappedInsertionSort`: an ordinary insertion sort over the half-open range
    // `[a, b)`, stepping by `gap` instead of 1. `RecordingEngine.compare` only compares two
    // live indices (there's no "compare against a captured snapshot value" primitive), so the
    // shift-then-final-write from ArrayV's `Writes.write` calls is expressed here as a chain of
    // adjacent-by-`gap` swaps, matching `ShellSort.swift`'s own gapped insertion loop.
    func gappedInsertionSort(_ a: Int, _ b: Int, _ gap: Int) {
      var i = a + gap
      while i < b {
        var j = i
        while j - gap >= a && !engine.compare(j, j - gap) {
          engine.swap(j, j - gap)
          j -= gap
        }
        i += gap
      }
    }

    // ArrayV's `recursiveShellSort`: recurse three times with the gap tripled (covering the
    // three residue classes `start`, `start+g`, `start+2g` modulo `3*g`) before running the
    // gapped insertion sort at the *current*, smaller gap — so gaps shrink as the recursion
    // unwinds, ending with an ordinary gap-1 insertion sort at the outermost call.
    func recursiveShellSort(_ start: Int, _ end: Int, _ g: Int) {
      if start + g <= end {
        recursiveShellSort(start, end, 3 * g)
        recursiveShellSort(start + g, end, 3 * g)
        recursiveShellSort(start + 2 * g, end, 3 * g)
        gappedInsertionSort(start, end, g)
      }
    }

    recursiveShellSort(0, n, 1)
  }
}
