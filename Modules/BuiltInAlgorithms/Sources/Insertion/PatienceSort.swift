import AlgorithmKit
import SortEngineKit

/// Patience sort, named for its resemblance to the card game: deal each value onto the leftmost
/// pile whose current top is `>=` it (starting a new pile if none qualifies), then repeatedly lift
/// the smallest top across every pile to rebuild the sorted order. Piles hold plain values, not
/// array positions — every comparison here (finding a pile's insertion point, finding the
/// currently-smallest top) is between two held values, neither a live array index, so it goes
/// through `engine.compareValues` rather than `engine.compare`/`engine.compareValue`.
///
/// The deal phase keeps `tops` sorted ascending as an invariant: choosing the *leftmost* pile with
/// `top >= x` and then dropping `x` onto it can only ever raise that pile's neighbor-to-the-left
/// comparison or lower its neighbor-to-the-right one, never break the ordering — so a binary search
/// suffices to find each card's pile in `O(log n)`. That invariant doesn't survive into the
/// collection phase, though: popping a pile's top can reveal a much larger card underneath, so
/// repeatedly finding the smallest top needs a real min-heap (mirroring ArrayV's own
/// `PriorityQueue`) rather than a linear scan, to keep the whole sort at `O(n log n)` instead of
/// degrading to `O(n^2)`.
public struct PatienceSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "patiencesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Patience Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 3570, coefficients: [239968, 120.471, 0.0149033],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0149033, 14.0609, -171.113], rSquared: 0.999899),
    implementationComplexity: 9,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "suit.spade.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    struct HeapEntry {
      let top: Int
      let pileIndex: Int
    }

    struct MinHeap {
      private var storage: [HeapEntry] = []

      var isEmpty: Bool { storage.isEmpty }

      mutating func push(_ engine: inout RecordingEngine, _ entry: HeapEntry) {
        storage.append(entry)
        var i = storage.count - 1
        while i > 0 {
          let parent = (i - 1) / 2
          if engine.compareValues(storage[parent].top, storage[i].top, by: (<=)) { break }
          storage.swapAt(parent, i)
          i = parent
        }
      }

      mutating func popMin(_ engine: inout RecordingEngine) -> HeapEntry {
        let result = storage[0]
        storage[0] = storage[storage.count - 1]
        storage.removeLast()
        var i = 0
        while true {
          let left = 2 * i + 1
          let right = 2 * i + 2
          var smallest = i
          if left < storage.count, engine.compareValues(storage[left].top, storage[smallest].top, by: (<)) {
            smallest = left
          }
          if right < storage.count, engine.compareValues(storage[right].top, storage[smallest].top, by: (<)) {
            smallest = right
          }
          if smallest == i { break }
          storage.swapAt(i, smallest)
          i = smallest
        }
        return result
      }
    }

    var piles: [[Int]] = []
    var tops: [Int] = []

    for i in 0..<n {
      let x = engine.values[i]
      var lo = 0
      var hi = piles.count
      while lo < hi {
        let mid = (lo + hi) / 2
        if engine.compareValues(tops[mid], x, by: (>=)) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      if lo == piles.count {
        piles.append([x])
        tops.append(x)
      } else {
        piles[lo].append(x)
        tops[lo] = x
      }
    }

    var heap = MinHeap()
    for i in 0..<piles.count {
      heap.push(&engine, HeapEntry(top: tops[i], pileIndex: i))
    }

    for c in 0..<n {
      let entry = heap.popMin(&engine)
      let value = piles[entry.pileIndex].removeLast()
      engine.setValue(c, value)
      if let newTop = piles[entry.pileIndex].last {
        heap.push(&engine, HeapEntry(top: newTop, pileIndex: entry.pileIndex))
      }
    }
  }
}
