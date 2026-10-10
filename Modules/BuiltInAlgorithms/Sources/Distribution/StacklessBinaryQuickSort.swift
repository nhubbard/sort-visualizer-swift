import Foundation
import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `StacklessBinaryQuickSort` — the same bit-radix partitioning as
/// `BinaryQuickSortingTemplate` (Hoare-style: route "bit clear" left, "bit set" right, then
/// recurse on both halves with the next-lower bit), but without a call stack *or* an explicit work
/// queue like `BinaryQuickSortIterative` uses. Instead, `i`/`b` track the current active range and
/// `q` the current bit, and the traversal always partitions the active range immediately (a
/// pre-order "descend left first" step via `b = p; q -= 1`). Once a range bottoms out at bit 0,
/// `m` — a counter that enumerates this binary recursion tree's nodes in the same pre-order the
/// traversal already visits them in — finds the next not-yet-visited sibling by counting how many
/// trailing bits of `m` are already set (`while !getBit(m, q + 1) { q += 1 }`): each such bit means
/// that level's left/right split is already fully behind us, so the search climbs one level higher
/// until it finds a level with an unvisited right sibling. The trailing `while` widens `b` to catch
/// up: elements at the boundary that share `m`'s higher bits belong to that sibling's range but
/// were never included when the original range was first carved out.
public struct StacklessBinaryQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklessbinaryquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Stackless Binary Quick Sort", bundle: .module),
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 3398, coefficients: [239951, 121.729, 0.015025],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.015025, 19.619, -199.602], rSquared: 0.999907),
    implementationComplexity: 19,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.branch"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func getBit(_ value: Int, _ bit: Int) -> Bool {
      (value >> bit) & 1 == 1
    }

    func partition(_ a: Int, _ b: Int, _ bit: Int) -> Int {
      var i = a - 1
      var j = b
      while true {
        i += 1
        while i < j {
          let isHighBit = getBit(engine.readValue(at: i), bit)
          engine.annotateLastOperation(
            stageID: "bitPartition", decisionID: "stacklessbinaryquicksort.scanLeft",
            outcome: isHighBit ? "stop" : "advance",
            roles: ["candidate": .arrayIndex(i)],
            explanationKey: "stacklessbinaryquicksort.scanLeft",
            explanation: isHighBit
              ? String(localized: "This value has a one in the active bit, so it belongs on the right side.", bundle: .module)
              : String(localized: "This value has a zero in the active bit, so continue scanning the left side.", bundle: .module))
          if isHighBit { break }
          i += 1
        }
        j -= 1
        while j > i {
          let isHighBit = getBit(engine.readValue(at: j), bit)
          engine.annotateLastOperation(
            stageID: "bitPartition", decisionID: "stacklessbinaryquicksort.scanRight",
            outcome: isHighBit ? "advance" : "stop",
            roles: ["candidate": .arrayIndex(j)],
            explanationKey: "stacklessbinaryquicksort.scanRight",
            explanation: isHighBit
              ? String(localized: "This value has a one in the active bit, so continue scanning the right side.", bundle: .module)
              : String(localized: "This value has a zero in the active bit, so it belongs on the left side.", bundle: .module))
          if !isHighBit { break }
          j -= 1
        }
        if i < j {
          engine.swap(i, j)
          engine.annotateLastOperation(
            stageID: "bucketExchange", decisionID: "stacklessbinaryquicksort.bucketExchange",
            outcome: "exchange", roles: ["left": .arrayIndex(i), "right": .arrayIndex(j)],
            explanationKey: "stacklessbinaryquicksort.bucketExchange",
            explanation: String(localized: "These values have opposite bits from their current partition sides, so exchange them.", bundle: .module))
        } else {
          return i
        }
      }
    }

    var q = BinaryQuickSortingTemplate.mostSignificantBit(engine.readAllValues())
    guard q >= 0 else { return }
    var m = 0
    var i = 0
    var b = n

    while i < n {
      let p = b - i < 1 ? i : partition(i, b, q)

      if q == 0 {
        m += 2
        while !getBit(m, q + 1) { q += 1 }

        i = b
        while b < n {
          let samePrefix = (engine.readValue(at: b) >> (q + 1)) == (m >> (q + 1))
          engine.annotateLastOperation(
            stageID: "bitGroup", decisionID: "stacklessbinaryquicksort.groupBoundary",
            outcome: samePrefix ? "continue" : "boundary",
            roles: ["candidate": .arrayIndex(b)],
            explanationKey: "stacklessbinaryquicksort.groupBoundary",
            explanation: samePrefix
              ? String(localized: "This value shares the higher-bit prefix, so keep it in the current group.", bundle: .module)
              : String(localized: "This value has a different higher-bit prefix, so the current group ends here.", bundle: .module))
          if !samePrefix { break }
          b += 1
        }
      } else {
        b = p
        q -= 1
      }
    }
  }
}
