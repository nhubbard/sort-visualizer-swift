import AlgorithmKit
import SortEngineKit

public struct StableCycleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stablecyclesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stable Cycle Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 207, coefficients: [237800, 2328.2, 5.70237],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.000120764, 4.94749, -0.170237], rSquared: 0.999986),
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
    // `a` is always the outer loop's fixed `i` (never the roaming `j`/`k`), and `engine.swap(i, k)`
    // below refreshes position `a` with the next value to route on every pass — so unlike plain
    // Cycle Sort's `t`, the value being routed here is always genuinely live at index `a`, and
    // every comparison against it is a real `engine.compare(_, a)`, not a held-value comparison.
    func destination1(_ a: Int, _ b1: Int, _ b: Int) -> Int {
      var d = a
      var e = 0
      for i in (a + 1)..<b {
        if engine.compare(i, a, by: <) {
          d += 1
        } else if i < b1 && !getBit(i) && engine.compare(i, a, by: ==) {
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
