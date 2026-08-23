import AlgorithmKit
import SortEngineKit

/// ArrayV's `WeavedMergeSort` — a merge sort that splits into interleaved ("weaved") strided
/// sub-sequences instead of contiguous left/right halves. `merge(residue, modulus)` recurses into
/// the "even" (`residue`, doubled modulus) and "odd" (`residue + modulus`, doubled modulus)
/// interleaved halves, then merges those two sorted strided runs back together at the original
/// `modulus` stride into a scratch buffer, copying the result back over `array`.
///
/// The merge's tie-break (`cmp == 0 && low > high` routes to `array[high]`) compares live index
/// values directly via `engine.values`, not `engine.compare` — matching how `CountingSort`/
/// `DoubleInsertionSort` read values directly for comparisons ArrayV itself performs via
/// `Reads.compareValues` rather than `Reads.compareIndices`.
///
/// `record` calls `merge` exactly once — there is no double-call artifact to reproduce.
public struct WeavedMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "weavedmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Weaved Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 5553, coefficients: [139568, 28.052],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [2.91183, 1.00013], rSquared: 0.999996),
    // The tie-break (`cmp == 0 && low > high` picks `array[high]`) decides between equal values
    // by their current strided *position*, not original input order — and since interleaving
    // scatters an original run of equal values across many strided sub-sequences, this does NOT
    // reduce to "preserve original order" the way a normal stable merge's tie-break does.
    // Confirmed via tagged-duplicate fuzzing: ties come out reordered.
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "shuffle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    let tempHandle = engine.createAuxArray(length: n)
    // The real backing store for the scratch buffer — `writeAux` only feeds the tape/visualizer,
    // it can't be read back, so the merge's actual working data lives here (mirroring how
    // `BottomUpMergeSort`/`MergeSort` keep their own shadow arrays alongside the aux writes).
    var tmp = engine.values

    func merge(_ residue: Int, _ modulus: Int) {
      guard residue + modulus < n else { return }

      var low = residue
      var high = residue + modulus
      let dmodulus = modulus << 1

      merge(low, dmodulus)
      merge(high, dmodulus)

      var nxt = residue
      while low < n && high < n {
        let takeHigh =
          engine.values[low] > engine.values[high]
          || (engine.values[low] == engine.values[high] && low > high)
        if takeHigh {
          tmp[nxt] = engine.values[high]
          engine.writeAux(tempHandle, at: nxt, value: engine.values[high])
          high += dmodulus
        } else {
          tmp[nxt] = engine.values[low]
          engine.writeAux(tempHandle, at: nxt, value: engine.values[low])
          low += dmodulus
        }
        nxt += modulus
      }

      if low >= n {
        while high < n {
          tmp[nxt] = engine.values[high]
          engine.writeAux(tempHandle, at: nxt, value: engine.values[high])
          nxt += modulus
          high += dmodulus
        }
      } else {
        while low < n {
          tmp[nxt] = engine.values[low]
          engine.writeAux(tempHandle, at: nxt, value: engine.values[low])
          nxt += modulus
          low += dmodulus
        }
      }

      var i = residue
      while i < n {
        engine.setValue(i, tmp[i])
        i += modulus
      }
    }

    merge(0, 1)

    engine.deleteAuxArray(tempHandle)
  }
}
