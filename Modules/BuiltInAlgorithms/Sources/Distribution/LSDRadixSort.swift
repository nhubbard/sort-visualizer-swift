import AlgorithmKit
import Foundation
import SortEngineKit

public struct LSDRadixSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lsdradixsort")
  public let metadata = AlgorithmMetadata(
    displayName: "LSD Radix Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 4292, coefficients: [239924, 105.28, 0.0115046],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0115046, 6.52513, -11.2883], rSquared: 0.999346),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times (n+b))", average: "O(d \\times (n+b))", worst: "O(d \\times (n+b))"
    ),
    spaceComplexity: "O(n + b)",
    iconName: "number"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    let radix = 4

    func getDigit(_ value: Int, _ place: Int) -> Int {
      (value / Int(pow(Double(radix), Double(place)))) % radix
    }

    var maxValue = 0
    for i in 0..<n {
      maxValue = max(maxValue, engine.values[i])
    }
    var highestPlace = 1
    while Int(pow(Double(radix), Double(highestPlace))) <= maxValue {
      highestPlace += 1
    }

    let outputHandle = engine.createAuxArray(length: n)
    // Reused across every pass instead of allocated fresh each time -- both are fully
    // overwritten by the end of each pass (`values` by the snapshot loop below, `output` by the
    // partitioning loop, since `counts`' prefix sum accounts for every index exactly once), so
    // there's no stale-data risk in keeping the same backing storage across passes.
    var values = [Int](repeating: 0, count: n)
    var output = [Int](repeating: 0, count: n)

    for place in 0..<highestPlace {
      var counts = [Int](repeating: 0, count: radix)
      for i in 0..<n {
        values[i] = engine.values[i]
      }
      for i in 0..<n {
        counts[getDigit(values[i], place)] += 1
      }
      for d in 1..<radix {
        counts[d] += counts[d - 1]
      }
      for i in stride(from: n - 1, through: 0, by: -1) {
        let digit = getDigit(values[i], place)
        counts[digit] -= 1
        output[counts[digit]] = values[i]
        engine.writeAux(outputHandle, at: counts[digit], value: values[i])
      }
      for i in 0..<n {
        engine.setValue(i, output[i])
      }
    }

    engine.deleteAuxArray(outputHandle)
  }
}
