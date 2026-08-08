import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `AmericanFlagSort` — an in-place, recursive MSD radix sort. One pass
/// counts each element's current digit into `count`, turns that into per-digit starting `offset`s,
/// then places every element directly into its bucket by following displacement cycles: pick up
/// the value sitting at one bucket's next free slot, write it to *its own* digit's next free slot,
/// pick up whatever was displaced there, and repeat until the chain closes back on its starting
/// slot. Each bucket's sub-range then recurses with the next-lower digit until a digit place is
/// exhausted or a bucket is trivially small.
///
/// ArrayV's own digit-count helper takes `log(value) / log(bucketCount)`, which breaks outright on
/// a zero-valued element (undefined) and can silently round a value sitting exactly on a power of
/// the radix down by one digit place — the same floating-point pitfall `MSDRadixSort`'s own doc
/// comment already flags. Replaced here with the same integer-only "count digit places until a
/// power of the radix exceeds the max value" technique that port already uses. Also fixed at radix
/// 4 rather than ArrayV's own configurable bucket count, matching every other radix-family port in
/// this codebase.
///
/// Cycle-following in-place permutation is assumed unstable here: a chase can visit same-digit
/// elements in an order unrelated to their original positions. This algorithm moves data purely
/// via `setValue`, never `swap`, so the swap-tape-shadow technique this codebase's other stability
/// tests rely on (`expectStable`, `tableSortIsStable`, etc.) can't reconstruct which original
/// element ended up where — a recorded `.setValue(i, v)` only says a value arrived, not which of
/// possibly several equal-valued originals it was, so there's no way to empirically confirm or
/// refute stability from the tape alone without instrumenting the port itself for testing
/// purposes. Left at the standard, conservative assumption for this class of algorithm.
public struct AmericanFlagSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "americanflagsort")
  public let metadata = AlgorithmMetadata(
    displayName: "American Flag Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2928, coefficients: [239957, 149.836, 0.0231814],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(d \\times (n+b))", average: "O(d \\times (n+b))", worst: "O(d \\times (n+b))"),
    spaceComplexity: "O(b)",
    iconName: "flag.checkered"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let radix = 4

    func getDigit(_ value: Int, _ divisor: Int) -> Int {
      (value / divisor) % radix
    }

    func americanFlagSort(_ start: Int, _ end: Int, _ divisor: Int) {
      var count = [Int](repeating: 0, count: radix)
      var offset = [Int](repeating: 0, count: radix)
      let countHandle = engine.createAuxArray(length: radix)
      let offsetHandle = engine.createAuxArray(length: radix)

      for i in start..<end {
        let digit = getDigit(engine.values[i], divisor)
        count[digit] += 1
        engine.writeAux(countHandle, at: digit, value: count[digit])
      }

      offset[0] = start
      engine.writeAux(offsetHandle, at: 0, value: offset[0])
      for i in 1..<radix {
        offset[i] = count[i - 1] + offset[i - 1]
        engine.writeAux(offsetHandle, at: i, value: offset[i])
      }

      for b in 0..<radix {
        while count[b] > 0 {
          let origin = offset[b]
          var from = origin
          var num = engine.values[from]
          repeat {
            let digit = getDigit(num, divisor)
            let to = offset[digit]
            offset[digit] += 1
            engine.writeAux(offsetHandle, at: digit, value: offset[digit])
            count[digit] -= 1
            engine.writeAux(countHandle, at: digit, value: count[digit])

            let displaced = engine.values[to]
            engine.setValue(to, num)
            num = displaced
            from = to
          } while from != origin
        }
      }

      engine.deleteAuxArray(offsetHandle)
      engine.deleteAuxArray(countHandle)

      if divisor > 1 {
        for i in 0..<radix {
          let begin = i > 0 ? offset[i - 1] : start
          let bucketEnd = offset[i]
          if bucketEnd - begin > 1 {
            americanFlagSort(begin, bucketEnd, divisor / radix)
          }
        }
      }
    }

    var maxValue = 0
    for i in 0..<n { maxValue = max(maxValue, engine.values[i]) }
    var numberOfDigits = 1
    var probe = radix
    while probe <= maxValue {
      numberOfDigits += 1
      probe *= radix
    }
    var maxDivisor = 1
    for _ in 0..<(numberOfDigits - 1) { maxDivisor *= radix }

    americanFlagSort(0, n, maxDivisor)
  }
}
