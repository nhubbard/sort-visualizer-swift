import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.POPLAR`, which calls directly into `PoplarHeapSort`'s own
/// `makeHeap` step rather than reimplementing it — mirrors that by calling
/// `PoplarHeapSort.swift`'s dedicated entry point, added specifically for this shuffle.
public struct PoplarifiedShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "poplar")
  public let metadata = ShuffleMetadata(displayName: "Poplarified")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    PoplarHeapSort().poplarHeapify(into: &engine)
  }
}
