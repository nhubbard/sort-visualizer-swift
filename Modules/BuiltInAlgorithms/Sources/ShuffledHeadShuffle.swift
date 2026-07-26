import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUFFLED_HEAD` — mirror of `ShuffledTailShuffle`, scanning from
/// the back. About 6/7 of elements stay compacted at the back in original relative order; the rest
/// are set aside, copied to the front, and shuffled among themselves.
///
/// Preserves a real off-by-one in ArrayV's source: the final shuffle call covers one fewer position
/// than the number of elements copied to the front, so the last set-aside element never
/// participates in the shuffle. Harmless (doesn't break length/permutation invariants), so left
/// as-is.
public struct ShuffledHeadShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "shuffledhead")
  public let metadata = ShuffleMetadata(displayName: "Scrambled Head")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    let auxHandle = engine.createAuxArray(length: n)
    var aux = [Int](repeating: 0, count: n)
    var values = engine.values

    var i = n - 1
    var j = n - 1
    var k = 0
    while i >= 0 {
      if Double.random(in: 0..<1) < 1.0 / 7.0 {
        aux[k] = values[i]
        engine.writeAux(auxHandle, at: k, value: values[i])
        k += 1
      } else {
        values[j] = values[i]
        engine.setValue(j, values[i])
        j -= 1
      }
      i -= 1
    }

    for m in 0..<k {
      values[m] = aux[m]
      engine.setValue(m, aux[m])
    }
    engine.deleteAuxArray(auxHandle)

    if j > 0 {
      for pos in 0..<j {
        engine.swap(pos, Int.random(in: pos..<j))
      }
    }
  }
}
