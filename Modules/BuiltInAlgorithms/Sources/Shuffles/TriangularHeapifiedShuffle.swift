import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.TRI_HEAP`, which calls directly into `TriangularHeapSort`'s own
/// `triangularHeapify` step rather than reimplementing it — mirrors that by calling
/// `TriangularHeapSort.swift`'s dedicated entry point, added specifically for this shuffle
/// alongside `SmoothSort.smoothHeapify`/`PoplarHeapSort.poplarHeapify`.
public struct TriangularHeapifiedShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "triheap")
  public let metadata = ShuffleMetadata(displayName: "Triangular Heapified")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    TriangularHeapSort().triangularHeapify(into: &engine)
  }
}
