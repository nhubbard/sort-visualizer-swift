import AlgorithmKit
import SortEngineKit

/// An LSD radix sort that avoids `LSDRadixSort`'s full-size output array by shuffling elements
/// around in place instead — at the cost of doing quadratically more element movement per digit
/// place than that counting-sort-based approach needs. For each digit place (least significant
/// first), `vregs[d - 1]` tracks the next slot (counting in from the end of the array) where an
/// element with digit value `d` should land this pass; every register starts at `n - 1` and only
/// ever moves inward. A single left-to-right scan then does the whole pass: an element already
/// showing digit `0` is already correctly grouped ahead of every nonzero digit for this place, so
/// the scan just steps over it (`pos` advances); anything else gets walked all the way out to its
/// own register's slot via a chain of adjacent swaps (a rotation, not a single swap — everything
/// between `pos` and the target slides over by one to make room), and every *lower* nonzero
/// digit's register shifts inward by one, since the slot it used to reserve just got claimed by
/// this element's rotation passing through it.
///
/// A rotation's cost is the distance it travels, and that distance isn't bounded by a constant —
/// it depends on how far this element's target register has already drifted inward, which is
/// itself a function of how many other elements this pass has already routed past it. Repeated
/// across a whole pass, that makes one digit place's total work quadratic in `n` rather than
/// linear, and this shows up empirically (measured, not just asymptotic): a size-256 run touches
/// on the order of 150,000 swaps per full sort, regardless of whether the input started sorted or
/// adversarially shuffled — the digit-place grouping this algorithm builds has no relationship to
/// whatever order the array started in.
public struct InPlaceLSDRadixSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "inplacelsdradixsort")
  public let metadata = AlgorithmMetadata(
    displayName: "In-Place LSD Radix Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 141, coefficients: [237470, 3949.39, 16.6802],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [16.6802, -754.42, 12224], rSquared: 0.999925),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n^2 log n)", average: "O(n^2 log n)", worst: "O(n^2 log n)"),
    spaceComplexity: "O(b)",
    iconName: "number.square.fill"
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

    var maxValue = 0
    for i in 0..<n { maxValue = max(maxValue, engine.values[i]) }
    var maxPower = 0
    var probe = radix
    while probe <= maxValue {
      maxPower += 1
      probe *= radix
    }

    let vregHandle = engine.createAuxArray(length: radix - 1)
    var vregs = [Int](repeating: 0, count: radix - 1)

    for power in 0...maxPower {
      for i in 0..<vregs.count {
        vregs[i] = n - 1
        engine.writeAux(vregHandle, at: i, value: vregs[i])
      }

      var pos = 0
      for _ in 0..<n {
        let digit = getDigit(engine.values[pos], power)
        if digit == 0 {
          pos += 1
        } else {
          let to = vregs[digit - 1]
          if to > pos {
            for k in pos..<to { engine.swap(k, k + 1) }
          } else if to < pos {
            for k in stride(from: pos, to: to, by: -1) { engine.swap(k, k - 1) }
          }
          for j in stride(from: digit - 1, to: 0, by: -1) {
            vregs[j - 1] -= 1
            engine.writeAux(vregHandle, at: j - 1, value: vregs[j - 1])
          }
        }
      }
    }

    engine.deleteAuxArray(vregHandle)
  }
}
