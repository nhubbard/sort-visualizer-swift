import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUFFLED_HALF`. Fully randomizes the array, then pigeonhole-sorts
/// only the first half back into order, leaving the second half fully scrambled.
public struct ShuffledHalfShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "shuffledhalf")
  public let metadata = ShuffleMetadata(displayName: "Shuffled Half")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }
    shuffleRange(&engine, from: 0, to: n)
    pigeonholeSortRange(&engine, from: 0, to: n / 2)
  }

  private func shuffleRange(_ engine: inout RecordingEngine, from start: Int, to end: Int) {
    for i in start..<end {
      engine.swap(i, Int.random(in: i..<end))
    }
  }

  private func pigeonholeSortRange(_ engine: inout RecordingEngine, from start: Int, to end: Int) {
    guard start < end else { return }
    var minValue = engine.values[start]
    var maxValue = minValue
    for i in (start + 1)..<end {
      let v = engine.values[i]
      if v < minValue { minValue = v }
      if v > maxValue { maxValue = v }
    }

    var holes = [Int](repeating: 0, count: maxValue - minValue + 1)
    for i in start..<end {
      holes[engine.values[i] - minValue] += 1
    }

    var j = start
    for i in 0..<holes.count {
      while holes[i] > 0 {
        holes[i] -= 1
        engine.setValue(j, i + minValue)
        j += 1
      }
    }
  }
}
