import SortEngineKit

/// Bundles a `RecordingEngine` aux-array handle with the real backing storage `engine.writeAux`
/// can't read back — see `BottomUpMergeSort.swift`'s doc comment for why every aux buffer needs
/// this dual bookkeeping. `QuadSortingTemplate` allocates several of these at different sizes
/// (16, 128, `length/2`), so this is a small reusable wrapper rather than repeating the pattern
/// by hand at each call site.
private struct AuxBuffer {
  let handle: AuxHandle
  var values: [Int]

  init(handle: AuxHandle, length: Int) {
    self.handle = handle
    values = [Int](repeating: 0, count: length)
  }

  mutating func write(_ engine: inout RecordingEngine, at index: Int, value: Int) {
    values[index] = value
    engine.writeAux(handle, at: index, value: value)
  }
}

/// Ported from ArrayV's `sorts/templates/QuadSorting` — Igor van den Hoven's real `quadsort.c`,
/// via ArrayV's Java re-implementation. One concrete algorithm currently extends this template
/// (`QuadSort`, filed under Merge despite the shared template's name); `FluxSort` (Hybrid) extends
/// it too but stays deferred — see `Documentation/docs/reference/port-status.md`.
///
/// Two systematic translation decisions apply throughout, both because `RecordingEngine` has no
/// concept matching ArrayV's `Reads.compareValues`/`Highlights.markArray`:
/// - `Reads.compareIndices(array, i, j, ...)` (always called with `mark=true` in the original)
///   becomes `engine.compare(i, j, by:)`, which auto-marks the same way. `Reads.compareValues(a,
///   b)` on two already-extracted (or aux-buffer) raw ints becomes a bare Swift comparison with no
///   engine call — the established precedent for this exact substitution is `WeavedMergeSort`'s
///   own doc comment. This does mean aux-to-aux and aux-to-main comparisons here don't increment
///   `compareCount`, matching how every other aux-heavy port in this codebase already handles it.
/// - ArrayV's decorative `Highlights.markArray(2/3, ...)`/`clearAllMarks()` calls (extra left/right
///   run highlighting during merges, layered on top of whatever `compare`/`swap` already
///   auto-mark) are dropped. No shipped merge port preserves ArrayV's own extra highlight timing,
///   and the raw marker numbers used here (`2`, `3`) don't correspond to this project's own
///   `Marker.secondary`/`Marker.pivot` — there's no clean mapping to preserve even if it seemed
///   worth it.
///
/// A `Writes.changeReversals(1); do { swap(pts++, ptt--) } while (reverse-- > 0)` block appears
/// three times in `quadSwap` below, always reversing the *original* `[pts, ptt]` range — each
/// becomes one `engine.reversal(pts, ptt)` call instead of manually replicating the decrementing
/// loop, matching how `PancakeSort`/`BurntPancakeSort` already use `engine.reversal` in place of a
/// manual swap loop. This differs from ArrayV's own swap count by exactly one no-op self-swap on
/// an odd-length range (the do-while unconditionally executes once more than `engine.reversal`'s
/// `low < high` loop does) — a cosmetic count discrepancy with no effect on the sorted result.
enum QuadSortingTemplate {

  // MARK: - Fixed-size sorting networks (QuadSortBase in the original)

  private static func swapTwo(_ engine: inout RecordingEngine, _ start: Int) {
    if engine.compare(start, start + 1, by: >) {
      engine.swap(start, start + 1)
    }
  }

  private static func swapThree(_ engine: inout RecordingEngine, _ start: Int) {
    if engine.compare(start, start + 1, by: >) {
      if engine.compare(start, start + 2, by: <=) {
        engine.swap(start, start + 1)
      } else if engine.compare(start + 1, start + 2, by: >) {
        engine.swap(start, start + 2)
      } else {
        let temp = engine.values[start]
        engine.setValue(start, engine.values[start + 1])
        engine.setValue(start + 1, engine.values[start + 2])
        engine.setValue(start + 2, temp)
      }
    } else if engine.compare(start + 1, start + 2, by: >) {
      if engine.compare(start, start + 2, by: >) {
        let temp = engine.values[start + 2]
        engine.setValue(start + 2, engine.values[start + 1])
        engine.setValue(start + 1, engine.values[start])
        engine.setValue(start, temp)
      } else {
        engine.swap(start + 2, start + 1)
      }
    }
  }

  private static func swapFour(_ engine: inout RecordingEngine, _ start: Int) {
    if engine.compare(start, start + 1, by: >) {
      engine.swap(start, start + 1)
    }
    if engine.compare(start + 2, start + 3, by: >) {
      engine.swap(start + 2, start + 3)
    }
    if engine.compare(start + 1, start + 2, by: >) {
      if engine.compare(start, start + 2, by: <=) {
        if engine.compare(start + 1, start + 3, by: <=) {
          engine.swap(start + 1, start + 2)
        } else {
          let temp = engine.values[start + 1]
          engine.setValue(start + 1, engine.values[start + 2])
          engine.setValue(start + 2, engine.values[start + 3])
          engine.setValue(start + 3, temp)
        }
      } else if engine.compare(start, start + 3, by: >) {
        engine.swap(start + 1, start + 3)
        engine.swap(start, start + 2)
      } else if engine.compare(start + 1, start + 3, by: <=) {
        let temp = engine.values[start + 1]
        engine.setValue(start + 1, engine.values[start])
        engine.setValue(start, engine.values[start + 2])
        engine.setValue(start + 2, temp)
      } else {
        let temp = engine.values[start + 1]
        engine.setValue(start + 1, engine.values[start])
        engine.setValue(start, engine.values[start + 2])
        engine.setValue(start + 2, engine.values[start + 3])
        engine.setValue(start + 3, temp)
      }
    }
  }

  /// Inserts the element at `end` into the already-sorted run `[start, end - 1]` (always exactly
  /// 4 elements: `swapFour` runs immediately before every call site) via a short unguarded
  /// insertion, checking up to 3 already-placed neighbors before falling back to the front.
  /// `end` is threaded explicitly rather than as a shared field the way ArrayV's `QuadSortBase`
  /// does — nothing outside this call chain (`swapFive`/`swapSix`/`swapSeven`/`swapEight`) ever
  /// reads it, so a field would only add indirection.
  private static func swapFive(_ engine: inout RecordingEngine, _ start: Int, _ end: inout Int) {
    end = start + 4
    var pta = end
    end += 1
    var ptt = pta
    pta -= 1

    if engine.compare(pta, ptt, by: >) {
      let key = engine.values[ptt]
      engine.setValue(ptt, engine.values[pta])
      ptt -= 1
      pta -= 1

      if pta > start, engine.values[pta - 1] > key {
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
      }

      if pta >= start, engine.values[pta] > key {
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
      }

      engine.setValue(ptt, key)
    }
  }

  /// Same shift logic as `swapFive`, one neighbor further out (checks `pta - 2` first) — valid
  /// because every call site already has at least 5 sorted elements behind `end` by construction
  /// (always called after `swapFive` or another `tailSwapEight` in the same chain).
  private static func tailSwapEight(_ engine: inout RecordingEngine, _ start: Int, _ end: inout Int)
  {
    var pta = end
    end += 1
    var ptt = pta
    pta -= 1

    if engine.compare(pta, ptt, by: >) {
      let key = engine.values[ptt]
      engine.setValue(ptt, engine.values[pta])
      ptt -= 1
      pta -= 1

      if engine.values[pta - 2] > key {
        for _ in 0..<3 {
          engine.setValue(ptt, engine.values[pta])
          ptt -= 1
          pta -= 1
        }
      }

      if pta > start, engine.values[pta - 1] > key {
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
      }

      if pta >= start, engine.values[pta] > key {
        engine.setValue(ptt, engine.values[pta])
        ptt -= 1
        pta -= 1
      }

      engine.setValue(ptt, key)
    }
  }

  private static func swapSix(_ engine: inout RecordingEngine, _ start: Int, _ end: inout Int) {
    swapFive(&engine, start, &end)
    tailSwapEight(&engine, start, &end)
  }

  private static func swapSeven(_ engine: inout RecordingEngine, _ start: Int, _ end: inout Int) {
    swapSix(&engine, start, &end)
    tailSwapEight(&engine, start, &end)
  }

  private static func swapEight(_ engine: inout RecordingEngine, _ start: Int, _ end: inout Int) {
    swapSeven(&engine, start, &end)
    tailSwapEight(&engine, start, &end)
  }

  /// `~4` items: one of the fixed sorting networks above. `5+`: an unguarded insertion sort —
  /// `swapFive`/`swapSix`/`swapSeven`/`swapEight` handle the first 5-8 elements by hand, then a
  /// binary-search insertion (the `while top > 1` loop) places everything past index 8.
  fileprivate static func tailSwap(_ engine: inout RecordingEngine, _ start: Int, _ nmemb: Int) {
    switch nmemb {
    case 0, 1:
      return
    case 2:
      swapTwo(&engine, start)
      return
    case 3:
      swapThree(&engine, start)
      return
    case 4:
      swapFour(&engine, start)
      return
    case 5:
      swapFour(&engine, start)
      var end = 0
      swapFive(&engine, start, &end)
      return
    case 6:
      swapFour(&engine, start)
      var end = 0
      swapSix(&engine, start, &end)
      return
    case 7:
      swapFour(&engine, start)
      var end = 0
      swapSeven(&engine, start, &end)
      return
    case 8:
      swapFour(&engine, start)
      var end = 0
      swapEight(&engine, start, &end)
      return
    default:
      break
    }

    swapFour(&engine, start)
    var end = 0
    swapEight(&engine, start, &end)
    end = start + 8
    var offset = 8

    while offset < nmemb {
      var top = offset
      offset += 1
      var pta = end
      end += 1
      var ptt = pta
      pta -= 1

      if engine.compare(pta, ptt, by: <=) { continue }

      let temp = engine.values[ptt]
      while top > 1 {
        let mid = top / 2
        if engine.values[pta - mid] > temp {
          pta -= mid
        }
        top -= mid
      }

      var i = ptt
      while i > pta {
        engine.setValue(i, engine.values[i - 1])
        i -= 1
      }
      engine.setValue(pta, temp)
    }
  }

  // MARK: - Parity merges (merge 4+4 into 8, or 8+8 into 16, tracking both ends at once)

  /// Merges the two 4-element runs at `[start, start+4)` and `[start+4, start+8)` from the main
  /// array into `dest` (an aux buffer), working from both ends toward the middle simultaneously —
  /// forward comparisons use `<=` and backward ones use `>`, which is what keeps this stable.
  private static func parityMerge4(
    _ engine: inout RecordingEngine, _ start: Int, _ dest: inout AuxBuffer, _ auxOffset: Int
  ) {
    var auxP = auxOffset
    var ptl = start
    var ptr = start + 4

    for _ in 0..<3 {
      if engine.values[ptl] <= engine.values[ptr] {
        dest.write(&engine, at: auxP, value: engine.values[ptl])
        ptl += 1
      } else {
        dest.write(&engine, at: auxP, value: engine.values[ptr])
        ptr += 1
      }
      auxP += 1
    }
    if engine.values[ptl] <= engine.values[ptr] {
      dest.write(&engine, at: auxP, value: engine.values[ptl])
    } else {
      dest.write(&engine, at: auxP, value: engine.values[ptr])
    }

    ptl = start + 3
    ptr = start + 7
    auxP += 4

    for _ in 0..<3 {
      if engine.values[ptl] > engine.values[ptr] {
        dest.write(&engine, at: auxP, value: engine.values[ptl])
        ptl -= 1
      } else {
        dest.write(&engine, at: auxP, value: engine.values[ptr])
        ptr -= 1
      }
      auxP -= 1
    }
    if engine.values[ptl] > engine.values[ptr] {
      dest.write(&engine, at: auxP, value: engine.values[ptl])
    } else {
      dest.write(&engine, at: auxP, value: engine.values[ptr])
    }
  }

  /// Same shape as `parityMerge4`, one level up: merges two 8-element runs from `from` (an aux
  /// buffer) back into the main array.
  private static func parityMerge8(_ engine: inout RecordingEngine, _ from: AuxBuffer, _ start: Int)
  {
    var mainP = start
    var ptl = 0
    var ptr = 8

    for _ in 0..<7 {
      if from.values[ptl] <= from.values[ptr] {
        engine.setValue(mainP, from.values[ptl])
        ptl += 1
      } else {
        engine.setValue(mainP, from.values[ptr])
        ptr += 1
      }
      mainP += 1
    }
    if from.values[ptl] <= from.values[ptr] {
      engine.setValue(mainP, from.values[ptl])
    } else {
      engine.setValue(mainP, from.values[ptr])
    }

    ptl = 7
    ptr = 15
    mainP += 8

    for _ in 0..<7 {
      if from.values[ptl] > from.values[ptr] {
        engine.setValue(mainP, from.values[ptl])
        ptl -= 1
      } else {
        engine.setValue(mainP, from.values[ptr])
        ptr -= 1
      }
      mainP -= 1
    }
    if from.values[ptl] > from.values[ptr] {
      engine.setValue(mainP, from.values[ptl])
    } else {
      engine.setValue(mainP, from.values[ptr])
    }
  }

  /// Merges four already-sorted 4-element runs (16 elements total) via two `parityMerge4` passes
  /// into `aux`, then one `parityMerge8` pass back — but only if they aren't already sorted,
  /// which the three `engine.compare` calls below check cheaply (and for real, unlike the bare
  /// value comparisons the merges themselves use — this fast path is genuinely visualized in
  /// ArrayV too, via `Reads.compareIndices`, not `Reads.compareValues`).
  fileprivate static func parityMerge16(
    _ engine: inout RecordingEngine, _ start: Int, _ aux: inout AuxBuffer
  ) {
    if engine.compare(start + 3, start + 4, by: <=),
      engine.compare(start + 7, start + 8, by: <=),
      engine.compare(start + 11, start + 12, by: <=)
    {
      return
    }

    parityMerge4(&engine, start, &aux, 0)
    parityMerge4(&engine, start + 8, &aux, 8)
    parityMerge8(&engine, aux, start)
  }

  // MARK: - Bottom-up tail merge (arrays under 256, and quadMerge's own fallback tail)

  private static func partialBackwardMerge(
    _ engine: inout RecordingEngine, _ aux: inout AuxBuffer, _ start: Int, _ nmemb: Int,
    _ block: Int
  ) {
    var m = start + block
    var e = start + nmemb - 1
    let r = m
    m -= 1

    if engine.compare(m, r, by: <=) { return }
    while engine.compare(m, e, by: <=) { e -= 1 }

    for i in r..<(r + (e - m)) {
      aux.write(&engine, at: i - r, value: engine.values[i])
    }

    var s = e - r
    engine.setValue(e, engine.values[m])
    e -= 1
    m -= 1

    if engine.values[start] <= aux.values[0] {
      repeat {
        while engine.values[m] > aux.values[s] {
          engine.setValue(e, engine.values[m])
          e -= 1
          m -= 1
        }
        engine.setValue(e, aux.values[s])
        e -= 1
        s -= 1
      } while s >= 0
    } else {
      repeat {
        while engine.values[m] <= aux.values[s] {
          engine.setValue(e, aux.values[s])
          e -= 1
          s -= 1
        }
        engine.setValue(e, engine.values[m])
        e -= 1
        m -= 1
      } while m >= start
      repeat {
        engine.setValue(e, aux.values[s])
        e -= 1
        s -= 1
      } while s >= 0
    }
  }

  /// Bottom-up merge pass: doubles `block` each round, merging every adjacent pair of runs at the
  /// current width via `partialBackwardMerge`, until `block` covers the whole `[start, start +
  /// nmemb)` range. Used directly for arrays under 256, and as `quadMerge`'s fallback tail for
  /// whatever doesn't divide evenly into quad blocks.
  fileprivate static func tailMerge(
    _ engine: inout RecordingEngine, _ aux: inout AuxBuffer, _ start: Int, _ nmemb: Int,
    _ block: Int
  ) {
    let pte = start + nmemb
    var block = block

    while block < nmemb {
      var pta = start
      while pta + block < pte {
        if pta + block * 2 < pte {
          partialBackwardMerge(&engine, &aux, pta, block * 2, block)
          pta += block * 2
          continue
        }
        partialBackwardMerge(&engine, &aux, pta, pte - pta, block)
        break
      }
      block *= 2
    }
  }

  // MARK: - Quad merge (arrays 256 and up)

  /// Merges main-array run `[start, start+block)` with aux-buffer run starting at `auxStart` (or
  /// vice versa, controlled by `toAux`) into the other side. Reads/writes always go through
  /// `read`/`write` below rather than `engine.values`/`aux.values` directly, so the same body
  /// covers both directions ArrayV's `forwardMerge(dest, from, ..., toAux)` needs.
  ///
  /// ArrayV unrolls this into groups of 3 comparisons per labeled-loop pass, purely as a C-style
  /// performance trick — each unrolled step still does exactly one comparison and one write, and
  /// falling out of the inner `for` normally lands at the same `while` re-check a `continue
  /// leftFirst`/`continue rightFirst` would, so the unrolling has no observable effect here. This
  /// translates it as the plain per-element loop it's equivalent to.
  private static func forwardMerge(
    _ engine: inout RecordingEngine, _ aux: inout AuxBuffer, _ start: Int, _ auxStart: Int,
    _ block: Int, _ toAux: Bool
  ) {
    func read(_ i: Int) -> Int { toAux ? engine.values[i] : aux.values[i] }
    func write(_ i: Int, _ value: Int) {
      if toAux {
        aux.write(&engine, at: i, value: value)
      } else {
        engine.setValue(i, value)
      }
    }

    var mergeP = toAux ? auxStart : start
    var l = toAux ? start : auxStart
    var r = toAux ? (start + block) : (auxStart + block)
    let m = r
    let e = r + block

    if read(r - 1) <= read(e - 1) {
      while l < m {
        if read(l) <= read(r) {
          write(mergeP, read(l))
          mergeP += 1
          l += 1
        } else {
          write(mergeP, read(r))
          mergeP += 1
          r += 1
        }
      }
      while r < e {
        write(mergeP, read(r))
        mergeP += 1
        r += 1
      }
    } else {
      while r < e {
        if read(l) > read(r) {
          write(mergeP, read(r))
          mergeP += 1
          r += 1
        } else {
          write(mergeP, read(l))
          mergeP += 1
          l += 1
        }
      }
      while l < m {
        write(mergeP, read(l))
        mergeP += 1
        l += 1
      }
    }
  }

  /// Merges 4 adjacent `block`-sized runs (`[start, start+4*block)`) into one sorted run, via up
  /// to 3 already-sorted fast-path checks (`engine.compare`, real visualized comparisons) that
  /// skip straight to a smaller merge — or none at all — when consecutive runs are already in
  /// order.
  private static func quadMergeBlock(
    _ engine: inout RecordingEngine, _ start: Int, _ aux: inout AuxBuffer, _ block: Int
  ) {
    let blockX2 = block * 2
    var cMax = start + block

    if engine.compare(cMax - 1, cMax, by: <=) {
      cMax += blockX2

      if engine.compare(cMax - 1, cMax, by: <=) {
        cMax -= block

        if engine.compare(cMax - 1, cMax, by: <=) {
          return
        }

        var pts = 0
        var c = start
        repeat {
          aux.write(&engine, at: pts, value: engine.values[c])
          c += 1
          pts += 1
        } while c < cMax

        cMax = c + blockX2
        repeat {
          aux.write(&engine, at: pts, value: engine.values[c])
          c += 1
          pts += 1
        } while c < cMax

        forwardMerge(&engine, &aux, start, 0, blockX2, false)
        return
      }

      var pts = 0
      var c = start
      cMax = start + blockX2
      repeat {
        aux.write(&engine, at: pts, value: engine.values[c])
        c += 1
        pts += 1
      } while c < cMax
    } else {
      forwardMerge(&engine, &aux, start, 0, block, true)
    }

    forwardMerge(&engine, &aux, start + blockX2, blockX2, block, true)
    forwardMerge(&engine, &aux, start, 0, blockX2, false)
  }

  /// Quad-merges the entire `[start, start+nmemb)` range, doubling `block` by 4 each round;
  /// falls back to `tailMerge` for whatever doesn't divide evenly into quad blocks at the current
  /// size, and again at the very end for the final, coarsest remainder.
  fileprivate static func quadMerge(
    _ engine: inout RecordingEngine, _ aux: inout AuxBuffer, _ start: Int, _ nmemb: Int,
    _ block: Int
  ) {
    let pte = start + nmemb
    var block = block * 4

    while block * 2 <= nmemb {
      var pta = start
      repeat {
        quadMergeBlock(&engine, pta, &aux, block / 4)
        pta += block
      } while pta + block <= pte
      tailMerge(&engine, &aux, pta, pte - pta, block / 4)
      block *= 4
    }
    tailMerge(&engine, &aux, start, nmemb, block / 4)
  }

  // MARK: - Pre-sort pass

  /// Pre-sorting pass: a 4-item sorting network applied across the whole range, with a
  /// side detector for strictly-decreasing runs — reversed in place via `engine.reversal` rather
  /// than merged, since a reversal is cheaper and exactly reproduces a decreasing run's sorted
  /// order. If the *entire* range turns out strictly decreasing, one reversal finishes the sort
  /// outright (returns 1); otherwise this finishes with parity-merge passes over what's left
  /// (returns 0, meaning the caller still has more merging to do).
  fileprivate static func quadSwap(_ engine: inout RecordingEngine, _ start: Int, _ nmemb: Int)
    -> Int
  {
    let swapHandle = engine.createAuxArray(length: 16)
    var swap = AuxBuffer(handle: swapHandle, length: 16)

    var pta = start
    var count = nmemb / 4
    var pts = 0

    swapper: while count > 0 {
      count -= 1

      innerA: while true {
        if engine.compare(pta, pta + 1, by: >) {
          if engine.compare(pta + 2, pta + 3, by: >) {
            if engine.compare(pta + 1, pta + 2, by: >) {
              pts = pta
              pta += 4
              break innerA
            }
            engine.swap(pta + 2, pta + 3)
          }
          engine.swap(pta, pta + 1)
        } else if engine.compare(pta + 2, pta + 3, by: >) {
          engine.swap(pta + 2, pta + 3)
        }

        if engine.compare(pta + 1, pta + 2, by: >) {
          if engine.compare(pta, pta + 2, by: <=) {
            if engine.compare(pta + 1, pta + 3, by: <=) {
              engine.swap(pta + 1, pta + 2)
            } else {
              let temp = engine.values[pta + 1]
              engine.setValue(pta + 1, engine.values[pta + 2])
              engine.setValue(pta + 2, engine.values[pta + 3])
              engine.setValue(pta + 3, temp)
            }
          } else if engine.compare(pta, pta + 3, by: >) {
            engine.swap(pta + 1, pta + 3)
            engine.swap(pta, pta + 2)
          } else if engine.compare(pta + 1, pta + 3, by: <=) {
            let temp = engine.values[pta + 1]
            engine.setValue(pta + 1, engine.values[pta])
            engine.setValue(pta, engine.values[pta + 2])
            engine.setValue(pta + 2, temp)
          } else {
            let temp = engine.values[pta + 1]
            engine.setValue(pta + 1, engine.values[pta])
            engine.setValue(pta, engine.values[pta + 2])
            engine.setValue(pta + 2, engine.values[pta + 3])
            engine.setValue(pta + 3, temp)
          }
        }
        pta += 4
        continue swapper
      }

      innerB: while true {
        if count > 0 {
          count -= 1

          if engine.compare(pta, pta + 1, by: >) {
            if engine.compare(pta + 2, pta + 3, by: >) {
              if engine.compare(pta + 1, pta + 2, by: >) {
                if engine.compare(pta - 1, pta, by: >) {
                  pta += 4
                  continue innerB
                }
              }
              engine.swap(pta + 2, pta + 3)
            }
            engine.swap(pta, pta + 1)
          } else if engine.compare(pta + 2, pta + 3, by: >) {
            engine.swap(pta + 2, pta + 3)
          }

          if engine.compare(pta + 1, pta + 2, by: >) {
            if engine.compare(pta, pta + 2, by: <=) {
              if engine.compare(pta + 1, pta + 3, by: <=) {
                engine.swap(pta + 1, pta + 2)
              } else {
                let temp = engine.values[pta + 1]
                engine.setValue(pta + 1, engine.values[pta + 2])
                engine.setValue(pta + 2, engine.values[pta + 3])
                engine.setValue(pta + 3, temp)
              }
            } else if engine.compare(pta, pta + 3, by: >) {
              engine.swap(pta, pta + 2)
              engine.swap(pta + 1, pta + 3)
            } else if engine.compare(pta + 1, pta + 3, by: <=) {
              let temp = engine.values[pta]
              engine.setValue(pta, engine.values[pta + 2])
              engine.setValue(pta + 2, engine.values[pta + 1])
              engine.setValue(pta + 1, temp)
            } else {
              let temp = engine.values[pta]
              engine.setValue(pta, engine.values[pta + 2])
              engine.setValue(pta + 2, engine.values[pta + 3])
              engine.setValue(pta + 3, engine.values[pta + 1])
              engine.setValue(pta + 1, temp)
            }
          }

          engine.reversal(pts, pta - 1)
          pta += 4
          continue swapper
        }

        if pts == start {
          switch nmemb % 4 {
          case 3:
            if engine.compare(pta + 1, pta + 2, by: <=) { break }
            fallthrough
          case 2:
            if engine.compare(pta, pta + 1, by: <=) { break }
            fallthrough
          case 1:
            if engine.compare(pta - 1, pta, by: <=) { break }
            fallthrough
          case 0:
            engine.reversal(pts, pts + nmemb - 1)
            engine.deleteAuxArray(swapHandle)
            return 1
          default:
            break
          }
        }

        engine.reversal(pts, pta - 1)
        break swapper
      }
    }

    tailSwap(&engine, pta, nmemb % 4)

    pta = start
    count = nmemb / 16
    while count > 0 {
      count -= 1
      parityMerge16(&engine, pta, &swap)
      pta += 16
    }

    if nmemb % 16 > 4 {
      tailMerge(&engine, &swap, pta, nmemb % 16, 4)
    }

    engine.deleteAuxArray(swapHandle)
    return 0
  }

  // MARK: - Entry point

  /// Top-level dispatch by size: under 16 is a plain `tailSwap`; under 256 pre-sorts via
  /// `quadSwap` then finishes with `tailMerge`; 256 and up finishes with the full `quadMerge`
  /// pass instead. Matches ArrayV's `QuadSort.runSort`, which always calls this (never
  /// `quadSortSwap`, the variant taking a caller-supplied swap array — nothing in this app's
  /// scope needs that entry point).
  static func sort(_ engine: inout RecordingEngine, start: Int, length: Int) {
    if length < 16 {
      tailSwap(&engine, start, length)
    } else if length < 256 {
      if quadSwap(&engine, start, length) == 0 {
        let handle = engine.createAuxArray(length: 128)
        var swap = AuxBuffer(handle: handle, length: 128)
        tailMerge(&engine, &swap, start, length, 16)
        engine.deleteAuxArray(handle)
      }
    } else {
      if quadSwap(&engine, start, length) == 0 {
        let handle = engine.createAuxArray(length: length / 2)
        var swap = AuxBuffer(handle: handle, length: length / 2)
        quadMerge(&engine, &swap, start, length, 16)
        engine.deleteAuxArray(handle)
      }
    }
  }
}
