import Foundation
import AlgorithmKit
import SortEngineKit

public struct RandomShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "random")
  public let metadata = ShuffleMetadata(displayName: String(localized: "Random", bundle: .module))
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    for i in stride(from: n - 1, to: 0, by: -1) {
      let j = engine.randomIndex(in: 0...i)
      engine.swap(i, j)
    }
  }
}
