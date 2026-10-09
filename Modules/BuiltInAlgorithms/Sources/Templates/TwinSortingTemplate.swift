import Foundation
import SortEngineKit

/// Ported from ArrayV's `sorts/templates/TwinSorting` — Igor van den Hoven's adaptive bottom-up
/// merge sort ("twinsort"). Only one concrete algorithm (`TwinSort`) extends this template in
/// ArrayV, and it uses the whole surface unmodified — a genuine one-consumer "shared template,"
/// ported here as a namespace purely to match this codebase's established template-porting
/// convention (see `BinaryQuickSortingTemplate`'s doc comment for why templates are namespaces of
/// `static func`s rather than nested closures). `twinsortSwap`/`tailsort` (ArrayV's other two
/// entry points into this template) are unreferenced by any current ArrayV subclass — not ported,
/// since nothing in this batch needs them; add them later if a future algorithm does.
enum TwinSortingTemplate {
  /// Scans adjacent pairs starting at `left`, skipping ascending pairs two at a time. When a
  /// descending run is found, tracks it until it ends, then reverses it in place. Returns `1` if
  /// the *entire* range turned out to be a single reversed run (nothing left to do — the caller
  /// should skip the merge phase entirely), else `0`.
  static func twinSwap(_ engine: inout RecordingEngine, _ left: Int, _ nmemb: Int) -> Int {
    var index = 0
    var end = nmemb - 2

    while index <= end {
      if engine.teachingCompare(
        index + left, index + 1 + left, by: (<=),
        stageID: "twin.run",
        whenTrue: String(localized: "This adjacent pair is nondecreasing, so Twin Sort extends the ascending run.", bundle: .module),
        whenFalse: String(localized: "This adjacent pair descends, so Twin Sort switches to a descending-run path.", bundle: .module)
      ) {
        index += 2
        continue
      }

      let start = index
      index += 2

      outer: while true {
        if index > end {
          if start == 0
            && (nmemb % 2 == 0 || engine.teachingCompare(
              index - 1 + left, index + left, by: (>),
              stageID: "twin.runTail",
              whenTrue: String(localized: "The final pair descends, so the whole run can reverse.", bundle: .module),
              whenFalse: String(localized: "The final pair breaks the descending run.", bundle: .module)
            )) {
            // The whole range is one descending run -- reverse it all and stop.
            end = nmemb - 1
            engine.teachingReversal(start + left, end + left, stageID: "twin.reverseRun", explanation: String(localized: "Reverse this descending run into ascending order.", bundle: .module))
            return 1
          }
          break outer
        }
        if engine.teachingCompare(
          index + left, index + 1 + left, by: (>),
          stageID: "twin.descendingRun",
          whenTrue: String(localized: "This pair descends, so Twin Sort extends its descending run.", bundle: .module),
          whenFalse: String(localized: "This pair ends the descending run.", bundle: .module)
        ) {
          if engine.teachingCompare(
            index - 1 + left, index + left, by: (>),
            stageID: "twin.runTail",
            whenTrue: String(localized: "The final pair descends, so the whole run can reverse.", bundle: .module),
            whenFalse: String(localized: "The final pair breaks the descending run.", bundle: .module)
          ) {
            index += 2
            continue
          }
          engine.swap(index + left, index + 1 + left)
        }
        break outer
      }

      end = index - 1
      engine.teachingReversal(start + left, end + left, stageID: "twin.reverseRun", explanation: String(localized: "Reverse this descending run into ascending order.", bundle: .module))
      end = nmemb - 2
      index += 2
    }

    return 0
  }

  /// Bottom-up merge, doubling `block` each pass. Copies the *right* block into `swap`, then
  /// merges starting from the tail ends of both blocks inward (writing the combined result into
  /// `engine` from the high end down) — needs at most `nmemb / 2` scratch space, reused across the
  /// whole sort. `swap` is a plain local buffer, not a visualized aux array: it never appears in
  /// its own right in ArrayV's visualizer either, it's pure bookkeeping for this merge technique.
  static func tailMerge(
    _ engine: inout RecordingEngine, _ left: Int, _ swap: inout [Int], _ nmemb: Int, _ block: Int
  ) {
    var block = block
    let s = 0

    while block < nmemb {
      var offset = 0
      while offset + block < nmemb {
        let a = offset
        let e0 = a + block - 1

        if engine.teachingCompare(
          e0 + left, e0 + 1 + left, by: (<=),
          stageID: "twin.mergeBoundary",
          whenTrue: String(localized: "These adjacent runs are already ordered, so this merge is skipped.", bundle: .module),
          whenFalse: String(localized: "The run boundary is reversed, so Twin Sort merges them.", bundle: .module)
        ) {
          // This adjacent pair of blocks is already in order -- skip the merge.
          offset += block * 2
          continue
        }

        var cMax: Int
        var dMax: Int
        if offset + block * 2 <= nmemb {
          cMax = s + block
          dMax = a + block * 2
        } else {
          cMax = s + nmemb - (offset + block)
          dMax = nmemb
        }

        // Shrink the merge if the tail of the right block is already >= the tail of the left
        // block (an early-exit for a partially-already-merged tail).
        var d = dMax - 1
        while engine.teachingCompare(
          e0 + left, d + left, by: (<=),
          stageID: "twin.trimTail",
          whenTrue: String(localized: "This right tail is already above the left tail, so it needs no merge work.", bundle: .module),
          whenFalse: String(localized: "This tail still crosses the merge boundary, so merging begins here.", bundle: .module)
        ) {
          dMax -= 1
          d -= 1
          cMax -= 1
        }

        // Copy the right block into swap[s..<cMax).
        var c = s
        d = a + block
        while c < cMax {
          swap[c] = engine.readValue(at: d + left)
          c += 1
          d += 1
        }
        c -= 1

        d = a + block - 1
        var e = dMax - 1

        if engine.teachingCompare(
          a + left, a + block + left, by: (<=),
          stageID: "twin.mergeDirection",
          whenTrue: String(localized: "The left run begins no greater, so merge starts from the left tail.", bundle: .module),
          whenFalse: String(localized: "The right run begins smaller, so merge starts from the buffered right tail.", bundle: .module)
        ) {
          // Left block's head is already <= right block's head: merge from the tail of the
          // LEFT block against the buffered right block.
          engine.setValue(e + left, engine.readValue(at: d + left))
          e -= 1
          d -= 1
          while c >= s {
            while engine.teachingCompareValue(
              d + left, against: swap[c], by: (>),
              stageID: "twin.mergeChoice",
              whenTrue: String(localized: "The left tail is larger, so the backward merge writes it next.", bundle: .module),
              whenFalse: String(localized: "The buffered right tail is at least as large, so merge takes it next.", bundle: .module)
            ) {
              engine.setValue(e + left, engine.readValue(at: d + left))
              e -= 1
              d -= 1
            }
            engine.setValue(e + left, swap[c])
            e -= 1
            c -= 1
          }
        } else {
          // Mirror branch: merge from the tail of the buffered right block first.
          engine.setValue(e + left, engine.readValue(at: d + left))
          e -= 1
          d -= 1
          while d >= a {
            while engine.teachingCompareValue(
              d + left, against: swap[c], by: (<=),
              stageID: "twin.mergeChoice",
              whenTrue: String(localized: "The left tail is no greater, so the backward merge writes the buffered right tail.", bundle: .module),
              whenFalse: String(localized: "The left tail is larger, so merge writes it next.", bundle: .module)
            ) {
              engine.setValue(e + left, swap[c])
              e -= 1
              c -= 1
            }
            engine.setValue(e + left, engine.readValue(at: d + left))
            e -= 1
            d -= 1
          }
          while c >= s {
            engine.setValue(e + left, swap[c])
            e -= 1
            c -= 1
          }
        }

        offset += block * 2
      }
      block *= 2
    }
  }

  /// Top-level entry: run-detection pre-pass, then (if needed) the tail-inward bottom-up merge
  /// with a freshly-allocated scratch buffer.
  static func twinsort(_ engine: inout RecordingEngine, _ nmemb: Int) {
    guard twinSwap(&engine, 0, nmemb) == 0 else { return }
    var swap = [Int](repeating: 0, count: nmemb / 2)
    tailMerge(&engine, 0, &swap, nmemb, 2)
  }
}
