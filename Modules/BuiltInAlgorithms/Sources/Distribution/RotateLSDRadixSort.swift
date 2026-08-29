import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `RotateLSDRadixSort` — an LSD radix sort with no O(n) bucket array:
/// each digit place (least significant first) gets a full in-place "sort by this one digit" pass
/// built from the same `multiSwap`/`rotate` block-rotation primitives `RotateMergeSort` already
/// uses, rather than a counting pass. `mergeSort` recurses on the index range exactly like an
/// ordinary merge sort; `merge` additionally recurses on the *digit-value* range `[da, db)`,
/// halving it every call via `binSearch` to find where each already-digit-sorted half crosses the
/// midpoint digit value, then `rotate`s the two "below the midpoint" runs together. Recursion
/// bottoms out either on a trivial index range or once the digit range narrows to one exact digit
/// value — at that point every element in range already carries that digit, so the call returns
/// without touching anything, which is what keeps a single digit-place pass stable with respect to
/// whatever order the previous (less-significant) pass left behind.
public struct RotateLSDRadixSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "rotatelsdradixsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Rotate LSD Radix Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 986, coefficients: [239959, 423.11, 0.181461],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.181461, 65.2687, -811.591], rSquared: 0.999786),
    implementationComplexity: 21,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times n log n)", average: "O(d \\times n log n)", worst: "O(d \\times n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.2.circlepath"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let base = 4

    func intPow(_ base: Int, _ exponent: Int) -> Int {
      var result = 1
      for _ in 0..<exponent { result *= base }
      return result
    }

    func getDigit(_ value: Int, _ place: Int) -> Int {
      (value / intPow(base, place)) % base
    }

    var maxValue = 0
    for i in 0..<n { maxValue = max(maxValue, engine.values[i]) }
    var maxPlace = 0
    var probe = base
    while probe <= maxValue {
      maxPlace += 1
      probe *= base
    }

    // Block-swaps the two equal-length adjacent ranges `[a, a+len)` and `[b, b+len)`.
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len { engine.swap(a + i, b + i) }
    }

    // Rotates the two adjacent blocks `[a, m)` and `[m, b)` so their relative order swaps, with
    // no auxiliary storage — same primitive `RotateMergeSort` uses.
    func rotate(_ a: Int, _ m: Int, _ b: Int) {
      var a = a
      var m = m
      var b = b
      var l = m - a
      var r = b - m
      while l > 0 && r > 0 {
        if r < l {
          multiSwap(m - r, m, r)
          b -= r
          m -= r
          l -= r
        } else {
          multiSwap(a, m, l)
          a += l
          m += l
          r -= l
        }
      }
    }

    // Finds the leftmost position in the digit-sorted range `[a, b)` whose digit-`place`
    // value is at least `d`.
    func binSearch(_ a: Int, _ b: Int, _ d: Int, _ place: Int) -> Int {
      var a = a
      var b = b
      while a < b {
        let mid = (a + b) / 2
        if getDigit(engine.values[mid], place) >= d {
          b = mid
        } else {
          a = mid + 1
        }
      }
      return a
    }

    // Merges the two adjacent digit-sorted runs `[a, m)` and `[m, b)`, whose digit-`place`
    // values are known to lie in `[da, db)`, by rotating each run's "below the digit midpoint"
    // prefix together and recursing into the two halves that produces.
    func merge(_ a: Int, _ m: Int, _ b: Int, _ da: Int, _ db: Int, _ place: Int) {
      guard b - a >= 2, db - da >= 2 else { return }
      let dm = (da + db) / 2
      let m1 = binSearch(a, m, dm, place)
      let m2 = binSearch(m, b, dm, place)
      rotate(m1, m, m2)
      let newM = m1 + (m2 - m)
      merge(newM, m2, b, dm, db, place)
      merge(a, m1, newM, da, dm, place)
    }

    func mergeSort(_ a: Int, _ b: Int, _ place: Int) {
      guard b - a >= 2 else { return }
      let mid = (a + b) / 2
      mergeSort(a, mid, place)
      mergeSort(mid, b, place)
      merge(a, mid, b, 0, base, place)
    }

    for place in 0...maxPlace {
      mergeSort(0, n, place)
    }
  }
}
