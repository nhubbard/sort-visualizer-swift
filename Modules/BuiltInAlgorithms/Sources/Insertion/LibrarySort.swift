import AlgorithmKit
import SortEngineKit

/// "Library Sort" (a.k.a. gapped insertion sort): elements live in a sparse `slots` array with
/// empty gaps interspersed between them, so most insertions only need to write into an
/// already-empty neighboring slot rather than shifting a large suffix of the array — the same
/// trick a librarian uses by leaving empty space on a shelf so a new book can slot in near its
/// alphabetical neighbors without re-shelving everything after it.
///
/// `positions` tracks the physical `slots` index of every real element placed so far, kept in the
/// same ascending order as their values (an invariant maintained by construction — a new element
/// is always placed strictly between its sorted neighbors). Whenever the structure fills
/// completely (`count == capacity`), `rebalance` doubles capacity and re-spreads the existing
/// elements one gap apart. Between rebalances, inserting a value whose target slot is already
/// occupied falls back to a local shift: scan forward for the nearest empty slot and shift
/// everything between the target and that gap over by one — cheap as long as gaps haven't been
/// fully consumed since the last rebalance, which the doubling keeps true on average. This gives
/// the same `O(n log n)` average / `O(n²)` worst case ArrayV's own `LibrarySort` cites (from
/// <https://en.wikipedia.org/wiki/Library_sort>) without needing ArrayV's own block-search
/// optimization, which is a pure performance trick, not part of the algorithm's identity.
///
/// Two deliberate departures from ArrayV's `LibrarySort.java`, both required rather than
/// stylistic:
/// - **No random tie-break.** ArrayV uses `java.util.Random` to pick among several equally-valued
///   candidate gaps — meaningless in `RecordingEngine`'s single deterministic tape (the same
///   category of problem the Bogo family already solved by going deterministic). Here, a new
///   value is always placed immediately after every already-present equal value (binary search
///   finds the first strictly-*greater* slot), which is deterministic and — as a side effect —
///   makes this sort stable, since equal values keep the relative order they were encountered in.
/// - **No `length`-valued sentinel.** ArrayV marks an empty slot with the value `length`, which
///   is safe there because ArrayV's own arrays only ever hold `0..<length`. This engine's arrays
///   aren't guaranteed to exclude the value `length` (e.g. a real run sorts `1...size`, where
///   `size == length` legitimately appears), so a `length` sentinel would silently misidentify a
///   real element as an empty gap. `Int.min` is used instead — safely outside the range of any
///   real fuzzed or production input.
///
/// Matching ArrayV's own comment ("there is supposed to be a shuffle here... removed to
/// demonstrate the O(n²) worst case"), elements are inserted in whatever order the array already
/// holds, with no shuffle step of its own.
public struct LibrarySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "librarysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Library Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 661, coefficients: [239642, 712.391, 0.529187],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.529187, 12.8053, -35.5912], rSquared: 0.999999),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "building.columns.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let empty = Int.min
    var capacity = 0
    var slots: [Int] = []
    // Physical `slots` index of each placed element, ascending by both position and value.
    var positions: [Int] = []
    let handle = engine.createAuxArray(length: 2 * n)

    func rebalance() {
      let count = positions.count
      let newCapacity = max(2, count * 2)
      var newSlots = [Int](repeating: empty, count: newCapacity)
      var newPositions = [Int]()
      newPositions.reserveCapacity(count)
      for (i, pos) in positions.enumerated() {
        let newPos = i * 2
        newSlots[newPos] = slots[pos]
        newPositions.append(newPos)
      }
      slots = newSlots
      positions = newPositions
      capacity = newCapacity
      for i in 0..<capacity {
        engine.writeAux(handle, at: i, value: slots[i])
      }
    }

    // Every real read of `slots` below (not just the writes already going through `writeAux`)
    // is a re-read of that same `writeAux`-shadowed buffer for a real decision, so it's marked
    // via `markAuxRead` right where it happens — same reasoning as `GravitySort`'s bucket
    // rescans, just against this sort's gapped-array shadow instead.
    func auxRead(at index: Int) -> Int {
      engine.markAuxRead(handle, at: index)
      return slots[index]
    }

    func insert(_ value: Int) {
      if positions.count == capacity {
        rebalance()
      }

      // Upper-bound binary search: first slot whose value is strictly greater than `value`.
      var lo = 0
      var hi = positions.count
      while lo < hi {
        let mid = (lo + hi) / 2
        if auxRead(at: positions[mid]) > value {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      let k = lo
      let targetPos = k == 0 ? 0 : positions[k - 1] + 1

      guard targetPos == capacity || auxRead(at: targetPos) != empty else {
        slots[targetPos] = value
        engine.writeAux(handle, at: targetPos, value: value)
        positions.insert(targetPos, at: k)
        return
      }

      // Either `targetPos` is already occupied (there's no gap between the elements
      // immediately before and after it, so `positions[k] == targetPos`), or `targetPos ==
      // capacity` (the new value is the largest so far and the last real element already
      // sits in the structure's very last slot, leaving no room after it). Either way, the
      // nearest free slot can be in *either* direction — repeated insertions can consume
      // every gap on one side of a busy region while leaving gaps untouched on the other, and
      // a new maximum has nothing to search rightward at all — so both directions are
      // searched and the shorter shift wins, the same "nearer side" choice ArrayV's own
      // `shiftExt` makes.
      var leftGap = targetPos - 1
      while leftGap >= 0, auxRead(at: leftGap) != empty {
        leftGap -= 1
      }
      var rightGap = targetPos
      while rightGap < capacity, auxRead(at: rightGap) != empty {
        rightGap += 1
      }
      let leftDistance = leftGap >= 0 ? targetPos - leftGap : Int.max
      let rightDistance = rightGap < capacity ? rightGap - targetPos : Int.max

      if rightDistance <= leftDistance {
        var i = rightGap
        while i > targetPos {
          slots[i] = slots[i - 1]
          engine.writeAux(handle, at: i, value: slots[i])
          i -= 1
        }
        for idx in k..<(k + (rightGap - targetPos)) {
          positions[idx] += 1
        }
        slots[targetPos] = value
        engine.writeAux(handle, at: targetPos, value: value)
        positions.insert(targetPos, at: k)
      } else {
        let shiftCount = (targetPos - 1) - leftGap
        var i = leftGap
        while i < targetPos - 1 {
          slots[i] = slots[i + 1]
          engine.writeAux(handle, at: i, value: slots[i])
          i += 1
        }
        for idx in (k - shiftCount)..<k {
          positions[idx] -= 1
        }
        slots[targetPos - 1] = value
        engine.writeAux(handle, at: targetPos - 1, value: value)
        positions.insert(targetPos - 1, at: k)
      }
    }

    for i in 0..<n {
      insert(engine.values[i])
    }

    for (i, pos) in positions.enumerated() {
      engine.setValue(i, slots[pos])
    }

    engine.deleteAuxArray(handle)
  }
}
