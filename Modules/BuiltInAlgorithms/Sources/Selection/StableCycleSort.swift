import AlgorithmKit
import SortEngineKit

public struct StableCycleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stablecyclesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stable Cycle Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 28576, coefficients: [239994, 11.8494, 0.000120764],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.2.circlepath.circle"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `bits` is a bit-packed `int[]` addressed via shift-and-mask arithmetic; that
    // packing is an implementation detail with nothing meaningful to visualize, so it's a plain
    // `[Bool]` here instead.
    var flagged = [Bool](repeating: false, count: n)

    func getBit(_ idx: Int) -> Bool {
      flagged[idx]
    }

    func flag(_ idx: Int) {
      flagged[idx] = true
    }

    // ArrayV's `destination1`: finds where the value held at index `a` belongs among
    // `array[a+1..<b]`. `d` counts strictly-lesser elements, like plain (unstable) Cycle Sort's
    // `countLesser` would.
    //
    // What makes this stable is `e`: within `[a+1, b1)` — `b1` is the ORIGINAL cycle-start
    // boundary, not the current `a` — it counts not-yet-flagged occurrences equal to the held
    // value, i.e. duplicates still waiting to be placed by this same cycle. The final loop walks
    // `d` past already-flagged slots and past those `e` reserved duplicate slots, landing on the
    // first genuinely free destination and preserving tie order.
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
