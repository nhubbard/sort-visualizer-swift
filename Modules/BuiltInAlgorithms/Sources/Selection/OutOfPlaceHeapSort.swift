import Foundation
import AlgorithmKit
import SortEngineKit

/// A bottom-up heapsort variant that never moves the heap's last element into the vacated root
/// the way `MaxHeapSort` does. Instead, each extraction writes the current root straight into an
/// external output buffer, marks the root slot with a `-1` sentinel, and sinks that "hole" down
/// to a leaf (`findNext`) by always swapping it with whichever child is itself still a hole, or
/// the larger real child otherwise — the sentinel never needs to be compared against a real
/// value, so it's checked via a direct `engine.values` read rather than `engine.compare`,
/// matching how ArrayV's own `array[l] == -1` is a raw field read with no `Reads.*` call. `-1` is
/// safe as a sentinel here because this engine's arrays always hold a permutation of `1...size`.
///
/// `siftDown` (used only to build the initial heap, never during extraction) is the "bottom-up"
/// heapify from <https://en.wikipedia.org/wiki/Heapsort#Bottom-up_heapsort>: descend along the
/// greater-child path all the way to a leaf, walk back up to find where the root's own value
/// belongs on that path, then shift the path's elements down one level at a time via direct
/// index swaps — fewer comparisons on average than a top-down sift because it skips comparing
/// against every intermediate level twice.
///
/// Stability: `false` — as with any heap extraction, sinking the hole can reorder equal
/// elements relative to each other.
public struct OutOfPlaceHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "outofplaceheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Out-of-Place Heap Sort", bundle: .module),
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1594, coefficients: [211425, 154.649, 0.00728488],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [14.3819, 1.03033], rSquared: 0.999922),
    implementationComplexity: 19,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "tray.and.arrow.down.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func siftDown(_ root: Int, _ size: Int) {
      var j = root
      while 2 * j + 1 < size {
        if 2 * j + 2 < size {
          j = engine.teachingCompare(
            2 * j + 2, 2 * j + 1,
            by: >,
            stageID: "OutOfPlaceHeapSort.childChoice",
            whenTrue: String(localized: "The right child is larger, so follow it in the heap.", bundle: .module),
            whenFalse: String(localized: "The left child is at least as large, so follow it.", bundle: .module)
          ) ? 2 * j + 2 : 2 * j + 1
        } else {
          j = 2 * j + 1
        }
      }
      while engine.teachingCompare(
        root, j, by: >, stageID: "OutOfPlaceHeapSort.siftPosition",
        whenTrue: String(localized: "The root is larger than this descendant, so move the landing point upward.", bundle: .module),
        whenFalse: String(localized: "The descendant can hold the root value at this heap position.", bundle: .module)
      ) {
        j = (j - 1) / 2
      }
      while j > root {
        engine.swap(root, j)
        j = (j - 1) / 2
      }
    }

    func findNext(_ size: Int) {
      var i = 0
      var l = 1
      var r = 2
      while r < size && !(engine.readValue(at: l) == -1 && engine.readValue(at: r) == -1) {
        if engine.readValue(at: l) == -1 {
          engine.swap(i, r)
          i = r
        } else if engine.readValue(at: r) == -1 {
          engine.swap(i, l)
          i = l
        } else if engine.teachingCompare(
          r, l, by: >, stageID: "OutOfPlaceHeapSort.nextLiveChild",
          whenTrue: String(localized: "The right live child is larger, so follow it to the next heap maximum.", bundle: .module),
          whenFalse: String(localized: "The left live child is at least as large, so follow it.", bundle: .module)
        ) {
          engine.swap(i, r)
          i = r
        } else {
          engine.swap(i, l)
          i = l
        }
        l = 2 * i + 1
        r = l + 1
      }
      if l < size && engine.readValue(at: l) != -1 {
        engine.swap(i, l)
      }
    }

    var i = (n - 1) / 2
    while i >= 0 {
      siftDown(i, n)
      i -= 1
    }

    let outHandle = engine.createAuxArray(length: n)
    // The real backing store for the output buffer — `writeAux` only feeds the tape/visualizer.
    var output = [Int](repeating: 0, count: n)

    i = n - 1
    while i >= 0 {
      let maxValue = engine.readValue(at: 0)
      output[i] = maxValue
      engine.writeAux(outHandle, at: i, value: maxValue)
      if engine.shouldAnnotateCurrentOperation {
        engine.annotateLastOperation(
          stageID: "OutOfPlaceHeapSort.extractToBuffer", outcome: "saved",
          roles: ["buffer": .auxiliaryIndex(handle: outHandle.rawValue, index: i),
            "maximum": .value(maxValue)],
          explanationKey: "OutOfPlaceHeapSort.extractToBuffer",
          explanation: String(localized: "Save the current heap maximum in its final buffered position.", bundle: .module))
      }
      engine.setValue(0, -1)
      findNext(n)
      i -= 1
    }

    for idx in 0..<n {
      engine.setValue(idx, output[idx])
      if engine.shouldAnnotateCurrentOperation {
        engine.annotateLastOperation(
          stageID: "OutOfPlaceHeapSort.restoreOutput", outcome: "placed",
          roles: ["output": .arrayIndex(idx), "bufferedValue": .value(output[idx])],
          explanationKey: "OutOfPlaceHeapSort.restoreOutput",
          explanation: String(localized: "Copy this buffered value into its final sorted array position.", bundle: .module))
      }
    }
    engine.deleteAuxArray(outHandle)
  }
}
