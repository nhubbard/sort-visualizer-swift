import AlgorithmKit
import SortEngineKit

/// Most-Significant-Digit Radix Sort — ported from ArrayV's `radixMSD`. Unlike `LSDRadixSort`
/// (single iterative counting-sort pass per digit, least-significant first), MSD recurses: each
/// call buckets the current `[min, max)` slice by one digit (most significant first), writes the
/// buckets back in order, then recurses into each bucket's sub-range with the next digit. A bucket
/// of size 0 or 1, or a range out of digits (`power < 0`), bottoms out the recursion.
///
/// One `createAuxArray`/`deleteAuxArray` pair per recursion frame stands in for ArrayV's per-frame
/// "registers" array.
public struct MSDRadixSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "msdradixsort")
  public let metadata = AlgorithmMetadata(
    displayName: "MSD Radix Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 4292, coefficients: [239924, 105.28, 0.0115046],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times n)", average: "O(d \\times n)", worst: "O(d \\times n)"),
    spaceComplexity: "O(n+b)",
    iconName: "square.stack.3d.forward.dottedline"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let radix = 4

    func intPow(_ base: Int, _ exponent: Int) -> Int {
      var result = 1
      for _ in 0..<exponent { result *= base }
      return result
    }

    func getDigit(_ value: Int, _ power: Int) -> Int {
      (value / intPow(radix, power)) % radix
    }

    // ArrayV's `Reads.analyzeMaxLog`: the most significant digit place that can distinguish
    // any value in the array, found without floating-point log (which can round a value that
    // sits exactly on a power of `radix` down by one and silently drop a whole digit place).
    var maxValue = 0
    for i in 0..<n {
      maxValue = max(maxValue, engine.values[i])
    }
    var highestPower = 0
    var probe = radix
    while probe <= maxValue {
      highestPower += 1
      probe *= radix
    }

    func radixMSD(_ min: Int, _ max: Int, _ power: Int) {
      guard min < max, power >= 0 else { return }

      // One fresh "registers" bucket array per recursion frame, exactly like ArrayV.
      var buckets = [[Int]](repeating: [], count: radix)
      for i in min..<max {
        buckets[getDigit(engine.values[i], power)].append(engine.values[i])
      }

      let handle = engine.createAuxArray(length: max - min)
      var writeIndex = min
      var auxIndex = 0
      for bucket in buckets {
        for value in bucket {
          engine.writeAux(handle, at: auxIndex, value: value)
          engine.setValue(writeIndex, value)
          writeIndex += 1
          auxIndex += 1
        }
      }

      // Recurse into each bucket's now-contiguous sub-range before releasing this frame's
      // aux array, matching ArrayV's transcribe-then-recurse-then-delete order.
      var start = min
      for bucket in buckets {
        radixMSD(start, start + bucket.count, power - 1)
        start += bucket.count
      }

      engine.deleteAuxArray(handle)
    }

    radixMSD(0, n, highestPower)
  }
}
