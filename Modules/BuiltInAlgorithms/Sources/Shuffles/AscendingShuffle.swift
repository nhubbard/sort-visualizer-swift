import AlgorithmKit
import SortEngineKit

/// The identity array `SortSession` hands every shuffle is already ascending — nothing to do.
/// Kept as an explicit, empty shuffle (matching v1's `ShuffleMethod.ascending`) rather than a
/// special-cased "no shuffle" option, so it shows up in the picker like any other choice.
public struct AscendingShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "ascending")
  public let metadata = ShuffleMetadata(displayName: "Ascending")
  public init() {}
  public func record(into engine: inout RecordingEngine) {}
}
