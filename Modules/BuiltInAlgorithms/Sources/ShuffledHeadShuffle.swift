import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUFFLED_HEAD` — the mirror image of `ShuffledTailShuffle`,
/// scanning from the back instead of the front. About 6/7 of the elements stay compacted at the
/// back in their original relative order; the rest are set aside and copied to the front, then
/// shuffled among themselves.
///
/// Faithfully ported including a real off-by-one quirk in ArrayV's own source: the final shuffle
/// call covers one fewer position than the number of elements actually copied to the front
/// (`shuffle(array, 0, j)` where `j` ends up one less than the aux count, rather than `j + 1`), so
/// the very last of the set-aside elements never actually participates in the shuffle. This doesn't
/// break the array-length or permutation invariants (unlike a real crash bug, which this codebase
/// does fix when found — see e.g. `DoubleInsertionSort`'s doc comment), so it's preserved as-is
/// rather than silently corrected.
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
