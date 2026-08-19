import AlgorithmKit
import SortEngineKit

/// Dijkstra's smoothsort: builds the array up as an adjacent run of "Leonardo heaps" — each of
/// size `LP[k]` (a Leonardo number, `LP[k] = LP[k-1] + LP[k-2] + 1`), analogous to how a binary
/// heapsort's implicit tree is a single heap of size `2^k - 1`. The run of heap sizes present at
/// any moment is tracked as a bitmap (`p`) over `LP` indices, right-shifted so its low bit lines
/// up with `pshift`, mirroring how `p`/`pshift` jointly encode a binary number the same way the
/// number of set bits below the heapified prefix does in ordinary bottom-up heap construction.
///
/// `sift` (build a Leonardo heap's root into place) and `trinkle` (restore the *whole run's*
/// heap-order property after a heap's root changes) are ArrayV's own names, kept because this is
/// a well-known, specifically-shaped algorithm (see e.g.
/// <https://en.wikipedia.org/wiki/Smoothsort>) rather than an invented one — divergent naming
/// would only make it harder to cross-reference against other implementations. `smoothHeapify`
/// is kept as its own entry point (a partial run with `fullSort: false`) rather than folded into
/// `record`, since `HeapifiedShuffle`'s `SMOOTH` sibling (`SmoothifiedShuffle`) calls this exact
/// step directly — see Documentation/docs/reference/port-status.md.
///
/// `sift`/`trinkle` hold a candidate value in a plain local (`val`), only ever writing it to its
/// final resting index once its correct position is found — the same "hole" shape already used
/// by `OutOfPlaceHeapSort.swift`'s bottom-up `siftDown`. Because `val` isn't tied to a live index
/// for most of that walk, comparisons against it read `engine.values` directly (uninstrumented,
/// no highlight) rather than through `engine.compare` — comparisons between two *genuinely live*
/// indices still go through `engine.compare` for real marking/counting. ArrayV's own
/// `Reads.compareValues` calls throughout `sift`/`trinkle` are likewise all value-only (never
/// `Reads.compareIndices`), so this isn't a departure from the source, just how this engine's
/// two-argument `compare` naturally maps back onto it. Shift/trailing-zero arithmetic uses
/// Swift's masking shift operators (`&>>`/`&<<`) rather than `>>`/`<<`, since Java's `int` shifts
/// silently mask their count to a 5-bit range — a difference that only matters for a
/// pathological all-zero edge case this algorithm's own structure never actually reaches, but
/// costs nothing to guard against.
///
/// Stability: `false` — `sift`/`trinkle` reorder equal elements the same way any heap-shaped sift
/// can.
public struct SmoothSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "smoothsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Smooth Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1647, coefficients: [239913, 270.663, 0.0757706],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "wave.3.right"
  )
  public init() {}

  private static let leonardo: [Int] = [
    1, 1, 3, 5, 9, 15, 25, 41, 67, 109,
    177, 287, 465, 753, 1219, 1973, 3193, 5167, 8361, 13529, 21891
  ]

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    smoothSort(into: &engine, lo: 0, hi: n - 1, fullSort: true)
  }

  func smoothSort(into engine: inout RecordingEngine, lo: Int, hi: Int, fullSort: Bool) {
    let lp = Self.leonardo

    func sift(_ pshiftIn: Int, _ headIn: Int) {
      var pshift = pshiftIn
      var head = headIn
      let val = engine.values[head]
      while pshift > 1 {
        let rt = head - 1
        let lf = head - 1 - lp[pshift - 2]
        if val >= engine.values[lf] && val >= engine.values[rt] { break }
        if engine.compare(lf, rt, by: >=) {
          engine.setValue(head, engine.values[lf])
          head = lf
          pshift -= 1
        } else {
          engine.setValue(head, engine.values[rt])
          head = rt
          pshift -= 2
        }
      }
      engine.setValue(head, val)
    }

    func trinkle(_ pIn: Int, _ pshiftIn: Int, _ headIn: Int, _ isTrustyIn: Bool) {
      var p = pIn
      var pshift = pshiftIn
      var head = headIn
      var isTrusty = isTrustyIn
      let val = engine.values[head]
      while p != 1 {
        let stepson = head - lp[pshift]
        if engine.values[stepson] <= val { break }
        if !isTrusty && pshift > 1 {
          let rt = head - 1
          let lf = head - 1 - lp[pshift - 2]
          if engine.compare(rt, stepson, by: >=) || engine.compare(lf, stepson, by: >=) {
            break
          }
        }
        engine.setValue(head, engine.values[stepson])
        head = stepson
        let trail = (p & ~1).trailingZeroBitCount
        p = p &>> trail
        pshift += trail
        isTrusty = false
      }
      if !isTrusty {
        engine.setValue(head, val)
        sift(pshift, head)
      }
    }

    var head = lo
    var p = 1
    var pshift = 1

    while head < hi {
      if (p & 3) == 3 {
        sift(pshift, head)
        p = p &>> 2
        pshift += 2
      } else {
        if lp[pshift - 1] >= hi - head {
          trinkle(p, pshift, head, false)
        } else {
          sift(pshift, head)
        }
        if pshift == 1 {
          p = p &<< 1
          pshift -= 1
        } else {
          p = p &<< (pshift - 1)
          pshift = 1
        }
      }
      p |= 1
      head += 1
    }

    if fullSort {
      trinkle(p, pshift, head, false)
      while pshift != 1 || p != 1 {
        if pshift <= 1 {
          let trail = (p & ~1).trailingZeroBitCount
          p = p &>> trail
          pshift += trail
        } else {
          p = p &<< 2
          p ^= 7
          pshift -= 2
          trinkle(p &>> 1, pshift + 1, head - lp[pshift] - 1, true)
          trinkle(p, pshift, head - 1, true)
        }
        head -= 1
      }
    }
  }

  public func smoothHeapify(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    smoothSort(into: &engine, lo: 0, hi: n - 1, fullSort: false)
  }
}
