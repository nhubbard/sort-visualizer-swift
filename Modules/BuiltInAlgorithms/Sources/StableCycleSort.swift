import AlgorithmKit
import SortEngineKit

public struct StableCycleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stablecyclesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stable Cycle Sort",
    category: .selection,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.2.circlepath.circle"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `bits` is a bit-packed `int[]` (`WLEN = 3`, 8 flag bits per `Int32`, addressed
    // via `idx >> WLEN` / `idx & 7` shift-and-mask arithmetic) recording which array positions
    // have already been rotated into their final resting place. That packing is purely an
    // implementation detail of the Java reference — it carries no meaning worth visualizing as
    // an array of numbers (unlike, say, CountingSort's tally array, which *is* the interesting
    // data), so it's represented here as a plain `[Bool]` instead. Functionally identical to
    // `getBit`/`flag` below, just without the bit arithmetic.
    var flagged = [Bool](repeating: false, count: n)

    func getBit(_ idx: Int) -> Bool {
      flagged[idx]
    }

    func flag(_ idx: Int) {
      flagged[idx] = true
    }

    // ArrayV's `destination1(array, bits, a, b1, b)`. Given the value held at index `a`
    // (captured once by the caller — `a` itself is never overwritten mid-cycle, matching
    // CycleSort's own held-value pattern), find where it belongs among `array[a+1..<b]`.
    //
    // `d` starts as `a` and counts every strictly-lesser element, exactly like CycleSort's
    // `countLesser` — this alone would be plain (unstable) Cycle Sort.
    //
    // What makes this variant *stable* is `e`: within `[a+1, b1)` specifically — `b1` is the
    // ORIGINAL start-of-cycle boundary, threaded through as `j` changes on each iteration of
    // the outer `do/while`, not the current `a` — count every element equal in value to the
    // held value that is *not yet flagged* (i.e. another occurrence of the same value still
    // waiting to be placed by this same cycle). Those `e` occurrences are duplicates that must
    // be skipped past so this particular occurrence lands in the correct position among its
    // ties, preserving their original relative order.
    //
    // The final `while` walks `d` forward past any position already flagged (already occupied
    // by a placed element) or past any of the `e` not-yet-flagged duplicate slots reserved by
    // this count, landing on the first genuinely free destination.
    func destination1(_ a: Int, _ b1: Int, _ b: Int) -> Int {
      let heldValue = engine.values[a]
      var d = a
      var e = 0
      for i in (a + 1)..<b {
        let v = engine.values[i]
        if v < heldValue {
          d += 1
        } else if i < b1 && !getBit(i) && v == heldValue {
          e += 1
        }
      }
      while getBit(d) || e > 0 {
        if !getBit(d) {
          e -= 1
        }
        d += 1
      }
      return d
    }

    for i in 0..<(n - 1) {
      guard !getBit(i) else { continue }
      var j = i
      repeat {
        let k = destination1(i, j, n)
        engine.swap(i, k)
        flag(k)
        j = k
      } while j != i
    }
  }
}
