import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SMOOTH`, which calls directly into `SmoothSort`'s own
/// `smoothHeapify` step rather than reimplementing it — mirrors that by calling
/// `SmoothSort.swift`'s dedicated entry point, added specifically for this shuffle.
public struct SmoothifiedShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "smooth")
  public let metadata = ShuffleMetadata(displayName: "Smoothified")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    SmoothSort().smoothHeapify(into: &engine)
  }
}
