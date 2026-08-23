import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `RotateMSDRadixSort` — the most-significant-digit counterpart to
/// `RotateLSDRadixSort`, reusing that same `multiSwap`/`rotate`/`binSearch`/`merge`/`mergeSort`
/// block-rotation machinery for `dist`'s one new step: digit-sort the active range by the current
/// digit, then `binSearch` for where digit values stop being `0` — the split between "done, digit
/// exhausted" and "still has a nonzero digit at this place, needs the next-lower digit next."
///
/// Recursing on the "done" side immediately (`b = p; q -= 1`) and stack-lessly resuming whichever
/// sibling range comes next via the same `i`/`b`/`q`/`m` bookkeeping
/// `StacklessBinaryQuickSort`/`StacklessAmericanFlagSort` use (there generalized from a binary bit
/// test to an r-ary digit test) is what avoids a call stack here despite this being, structurally,
/// a full recursive MSD radix sort.
public struct RotateMSDRadixSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "rotatemsdradixsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Rotate MSD Radix Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1190, coefficients: [239661, 365.413, 0.137435],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.137435, 38.3174, -558.331], rSquared: 0.999615),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times n log n)", average: "O(d \\times n log n)", worst: "O(d \\times n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.2.circlepath.circle"
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

    func shift(_ value: Int, _ places: Int) -> Int {
      var value = value
      var places = places
      while places > 0 {
        value /= base
        places -= 1
      }
      return value
    }

    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len { engine.swap(a + i, b + i) }
    }

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

    // Digit-sorts `[a, b)` by `place`, then returns the split between digit-`0` elements and
    // everything else.
    func dist(_ a: Int, _ b: Int, _ place: Int) -> Int {
      mergeSort(a, b, place)
      return binSearch(a, b, 1, place)
    }

    var maxValue = 0
    for i in 0..<n { maxValue = max(maxValue, engine.values[i]) }
    var q = 0
    var probe = base
    while probe <= maxValue {
      q += 1
      probe *= base
    }

    var m = 0
    var i = 0
    var b = n

    while i < n {
      let p = b - i < 1 ? i : dist(i, b, q)

      if q == 0 {
        m += base
        var t = m / base
        while t % base == 0 {
          t /= base
          q += 1
        }

        i = b
        while b < n && shift(engine.values[b], q + 1) == shift(m, q + 1) {
          b += 1
        }
      } else {
        b = p
        q -= 1
      }
    }
  }
}
