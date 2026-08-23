import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `StacklessAmericanFlagSort` — the same `i`/`b`/`q`/`m` stack-free
/// quadrant walk `StacklessBinaryQuickSort` uses to avoid a call stack, generalized from a binary
/// bit test to an r-ary digit test, with `AmericanFlagSort`'s counting-and-cycle-follow as the
/// per-quadrant distribute step instead of a binary partition.
///
/// `dist` differs from `AmericanFlagSort.sort`'s cycle-follow in one structural way: it drains
/// each bucket from its *last* slot backward (`cnts[digit]` counts down from the bucket's end
/// boundary) instead of `AmericanFlagSort`'s forward fill from the bucket's start — and it only
/// ever explicitly processes buckets `0..<radix-1`, relying on the same "last bucket falls into
/// place once every other one is drained" property `AmericanFlagSort` also depends on. Also skips
/// straight to the digit-`0`/non-digit-`0` split point (`dist` returns `a + offs[1]`, the boundary
/// after bucket `0`) rather than fully placing every bucket at once, matching the same "descend
/// into the first bucket now, the walk's `m` counter resumes the rest later" shape
/// `RotateMSDRadixSort`'s `dist` also uses.
///
/// Like `AmericanFlagSort`, cycle-following in-place permutation reads as unstable by default, and
/// this port moves data purely via `setValue` too — so the swap-tape-shadow technique this
/// codebase's other stability tests rely on can't reconstruct which original element ended up
/// where (a recorded `.setValue(i, v)` only says a value arrived, not which of possibly several
/// equal-valued originals it was). Left at the standard, conservative assumption for this class of
/// algorithm, same as `AmericanFlagSort`.
public struct StacklessAmericanFlagSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklessamericanflagsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stackless American Flag Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 3270, coefficients: [239941, 132.795, 0.0181722],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0181722, 13.9485, 16.2217], rSquared: 0.999545),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times (n+b))", average: "O(d \\times (n+b))", worst: "O(d \\times (n+b))"),
    spaceComplexity: "O(b)",
    iconName: "flag.checkered.2.crossed"
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

    func getDigit(_ value: Int, _ place: Int) -> Int {
      (value / intPow(radix, place)) % radix
    }

    func shift(_ value: Int, _ places: Int) -> Int {
      var value = value
      var places = places
      while places > 0 {
        value /= radix
        places -= 1
      }
      return value
    }

    var maxValue = 0
    for i in 0..<n { maxValue = max(maxValue, engine.values[i]) }
    var q = 0
    var probe = radix
    while probe <= maxValue {
      q += 1
      probe *= radix
    }

    var cnts = [Int](repeating: 0, count: radix)
    var offs = [Int](repeating: 0, count: radix)
    let countsHandle = engine.createAuxArray(length: radix)
    let offsHandle = engine.createAuxArray(length: radix)

    func bumpCount(_ digit: Int) {
      cnts[digit] += 1
      engine.writeAux(countsHandle, at: digit, value: cnts[digit])
    }

    // Digit-sorts `[a, b)` by `place` via counting + cycle-follow (assuming `cnts` already
    // holds each bucket's raw count for this range), then returns the split point after
    // bucket 0.
    func dist(_ a: Int, _ b: Int, _ place: Int) -> Int {
      for i in 1..<radix {
        cnts[i] += cnts[i - 1]
        offs[i] = cnts[i - 1]
        engine.writeAux(countsHandle, at: i, value: cnts[i])
        engine.writeAux(offsHandle, at: i, value: offs[i])
      }

      for i in 0..<(radix - 1) {
        let pos = a + offs[i]
        if cnts[i] > offs[i] {
          var held = engine.values[pos]
          repeat {
            let digit = getDigit(held, place)
            cnts[digit] -= 1
            engine.writeAux(countsHandle, at: digit, value: cnts[digit])
            let displaced = engine.values[a + cnts[digit]]
            engine.setValue(a + cnts[digit], held)
            held = displaced
          } while cnts[i] > offs[i]
        }
      }

      let split = a + offs[1]
      for i in 0..<radix {
        cnts[i] = 0
        offs[i] = 0
        engine.writeAux(countsHandle, at: i, value: 0)
        engine.writeAux(offsHandle, at: i, value: 0)
      }
      return split
    }

    var m = 0
    var i = 0
    var b = n

    for j in i..<b {
      bumpCount(getDigit(engine.values[j], q))
    }

    while i < n {
      let p = b - i < 1 ? i : dist(i, b, q)

      if q == 0 {
        m += radix
        var t = m / radix
        while t % radix == 0 {
          t /= radix
          q += 1
        }

        i = b
        while b < n && shift(engine.values[b], q + 1) == shift(m, q + 1) {
          bumpCount(getDigit(engine.values[b], q))
          b += 1
        }
      } else {
        b = p
        q -= 1
        for j in i..<b {
          bumpCount(getDigit(engine.values[j], q))
        }
      }
    }

    engine.deleteAuxArray(offsHandle)
    engine.deleteAuxArray(countsHandle)
  }
}
