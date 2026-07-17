import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.INTERLACED`. Leaves position 0 alone, then fills every even
/// position (2, 4, 6, ...) from the front of the rest of the array and every odd position
/// (1, 3, 5, ...) from the back, working inward from both ends at once.
public struct InterlacedShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "interlaced")
  public let metadata = ShuffleMetadata(displayName: "Interlaced")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let reference = engine.values

    var leftIndex = 1
    var rightIndex = n - 1
    for i in 1..<n {
      if i.isMultiple(of: 2) {
        engine.setValue(i, reference[leftIndex])
        leftIndex += 1
      } else {
        engine.setValue(i, reference[rightIndex])
        rightIndex -= 1
      }
    }
  }
}
