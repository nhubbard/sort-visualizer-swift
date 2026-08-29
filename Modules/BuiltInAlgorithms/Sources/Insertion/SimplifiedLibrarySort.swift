import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `SimplifiedLibrarySort` — gapped insertion sort ("Library Sort"): a sorted
/// "spine" of `j` elements with empty gaps between them, so new elements rarely require reshuffling
/// the whole array.
///
/// Each new element is binary-searched against the spine to find its gap, tallied per-gap in
/// `cnts`. Once a batch of `R * j - j` elements fills up, `rebalance` runs: gap counts become gap
/// offsets via partial sum, spine + batch elements are written into a `temp` buffer at their gap's
/// offset, `temp` is copied back over the live array, and each gap's batch run is locally sorted.
/// The spine then grows to `j = i` and the process repeats.
///
/// Arrays under 32 elements skip the gap machinery and fall back to a single binary insertion sort,
/// matching ArrayV's own `length < 32` special case — `sizeRange`'s lower bound stays at 32 so the
/// gap logic is actually exercised.
public struct SimplifiedLibrarySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "simplifiedlibrarysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Simplified Library Sort",
    category: .insertion,
    sizeRange: 32...256,
    growthModel: OperationGrowthModel(
      anchorSize: 384, coefficients: [239914, 1203.82, 1.5031],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [1.5031, 49.4357, -710.621], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "books.vertical.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Rebalancing factor: gaps are re-sized once the spine has absorbed `R` times its own
    // length in new elements. ArrayV hardcodes this as a `private final int R = 4`.
    let rebalanceFactor = 4

    // Range-scoped generalization of the shipped `BinaryInsertionSort.record`, sorting the
    // half-open range `[start, end)` instead of the whole array — this is ArrayV's
    // `BinaryInsertionSort.customBinaryInsert(array, start, end, sleep)`, used both for the
    // initial whole-spine sort and for locally sorting each gap's batch of new elements after
    // `rebalance` has bucketed them. `num` (the element being inserted) is always a live index
    // within the range being sorted, exactly like the whole-array version, so this reuses
    // `engine.compare` rather than a held-value comparison.
    func binaryInsert(_ start: Int, _ end: Int) {
      guard end - start > 1 else { return }
      for i in (start + 1)..<end {
        var lo = start
        var hi = i
        while lo < hi {
          let mid = lo + (hi - lo) / 2
          // Do NOT move equal elements to the right of the inserted element; this
          // maintains stability.
          if engine.compare(i, mid, by: <) {
            hi = mid
          } else {
            lo = mid + 1
          }
        }
        var shiftIndex = i
        while shiftIndex > lo {
          engine.swap(shiftIndex, shiftIndex - 1)
          shiftIndex -= 1
        }
      }
    }

    // ArrayV's separate `binarySearch(array, a, b, val, sleep)`: finds where `val` would
    // insert among the sorted spine `[a, b)`. Unlike `binaryInsert` above, `val` here is
    // `engine.values[i]` for an `i` *outside* `[a, b)` (a not-yet-classified batch element), so
    // it's a held value compared against a live spine index — `engine.compareValue`, the same
    // pattern `IntroSort`'s cached pivot uses, not `engine.compare`'s two-live-index shape.
    func gapSearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
      var lo = a
      var hi = b
      while lo < hi {
        let mid = lo + (hi - lo) / 2
        if engine.compareValue(mid, against: val, by: (>)) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      return lo
    }

    // ArrayV's `getMinLevel`: shrinks `n` down to a starting spine size below 32.
    func getMinLevel(_ initial: Int) -> Int {
      var value = initial
      while value >= 32 {
        value = (value - 1) / rebalanceFactor + 1
      }
      return value
    }

    if n < 32 {
      binaryInsert(0, n)
      return
    }

    var spineSize = getMinLevel(n)
    binaryInsert(0, spineSize)

    var maxLevel = spineSize
    while maxLevel * rebalanceFactor < n {
      maxLevel *= rebalanceFactor
    }

    // Three scratch buffers, mirroring ArrayV's three `Writes.createExternalArray` calls.
    // `writeAux` only feeds the tape/visualizer and can't be read back, so each aux handle is
    // paired with a plain local Swift array that holds the real working data — the same
    // shadow-array pattern `BottomUpMergeSort`/`MSDRadixSort`/`CountingSort` use for their own
    // scratch buffers.
    let tempHandle = engine.createAuxArray(length: n)
    var tempShadow = [Int](repeating: 0, count: n)
    let cntsHandle = engine.createAuxArray(length: maxLevel + 2)
    var cntsShadow = [Int](repeating: 0, count: maxLevel + 2)
    let locsHandle = engine.createAuxArray(length: n - maxLevel)
    var locsShadow = [Int](repeating: 0, count: n - maxLevel)

    // Redistributes the `m` sorted spine elements and the `b - m` classified batch elements
    // (their gap assignments recorded in `locsShadow[0..<(b - m)]`, their per-gap tallies in
    // `cntsShadow`) into freshly-sized gaps, then locally sorts each gap's batch of new
    // elements.
    func rebalance(_ m: Int, _ b: Int) {
      // Partial sum: turn per-gap counts (stashed at `cntsShadow[gap + 1]` during
      // classification) into per-gap starting offsets within `temp`.
      for i in 0..<m {
        let updated = cntsShadow[i + 1] + cntsShadow[i] + 1
        cntsShadow[i + 1] = updated
        engine.writeAux(cntsHandle, at: i + 1, value: updated)
      }

      // Place the classified batch elements into their gaps' offsets, consuming offsets
      // left-to-right within a gap so ties among that gap's batch elements keep the order
      // they were classified in.
      var k = 0
      for i in m..<b {
        let loc = locsShadow[k]
        let pos = cntsShadow[loc]
        let value = engine.values[i]
        tempShadow[pos] = value
        engine.writeAux(tempHandle, at: pos, value: value)
        cntsShadow[loc] = pos + 1
        engine.writeAux(cntsHandle, at: loc, value: pos + 1)
        k += 1
      }

      // Place the spine elements right after however many batch elements just filled their
      // own gap.
      for i in 0..<m {
        let pos = cntsShadow[i]
        let value = engine.values[i]
        tempShadow[pos] = value
        engine.writeAux(tempHandle, at: pos, value: value)
        cntsShadow[i] = pos + 1
        engine.writeAux(cntsHandle, at: i, value: pos + 1)
      }

      // Copy the freshly-gapped layout back over the live array — ArrayV's
      // `Writes.arraycopy(temp, 0, array, 0, b, ...)`.
      for i in 0..<b {
        engine.setValue(i, tempShadow[i])
      }

      // Locally sort each gap's run of batch elements. `cntsShadow[g]` (post-placement) now
      // marks one-past the spine element that anchors gap `g`, so gap `g + 1`'s batch run is
      // `[cntsShadow[g], cntsShadow[g + 1] - 1)` — excluding the spine element that follows
      // it. Gap 0 (before the first spine element) and gap `m` (after the last) are handled
      // as the two boundary cases.
      binaryInsert(0, cntsShadow[0] - 1)
      for i in 0..<(m - 1) {
        binaryInsert(cntsShadow[i], cntsShadow[i + 1] - 1)
      }
      binaryInsert(cntsShadow[m - 1], cntsShadow[m])

      // Reset the count array for the next batch.
      for i in 0..<(m + 2) {
        cntsShadow[i] = 0
        engine.writeAux(cntsHandle, at: i, value: 0)
      }
    }

    var i = spineSize
    var k = 0
    while i < n {
      if rebalanceFactor * spineSize == i {
        rebalance(spineSize, i)
        spineSize = i
        k = 0
      }

      // Classify which of the `spineSize + 1` gaps `engine.values[i]` belongs in, and tally
      // it for the upcoming rebalance.
      let loc = gapSearch(0, spineSize, engine.values[i])
      let updatedCount = cntsShadow[loc + 1] + 1
      cntsShadow[loc + 1] = updatedCount
      engine.writeAux(cntsHandle, at: loc + 1, value: updatedCount)
      locsShadow[k] = loc
      engine.writeAux(locsHandle, at: k, value: loc)
      k += 1
      i += 1
    }
    rebalance(spineSize, n)

    engine.deleteAuxArray(tempHandle)
    engine.deleteAuxArray(cntsHandle)
    engine.deleteAuxArray(locsHandle)
  }
}
