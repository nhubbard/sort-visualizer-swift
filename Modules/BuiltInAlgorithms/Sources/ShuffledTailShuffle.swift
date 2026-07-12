import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUFFLED_TAIL`. Scans the array once, keeping about 6/7 of the
/// elements compacted at the front in their original relative order, while the remaining ~1/7 are
/// set aside (in an auxiliary buffer, in original relative order) and appended after the compacted
/// prefix — that appended tail is then Fisher-Yates shuffled among itself.
public struct ShuffledTailShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "shuffledtail")
    public let metadata = ShuffleMetadata(displayName: "Scrambled Tail")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }

        let auxHandle = engine.createAuxArray(length: n)
        var aux = [Int](repeating: 0, count: n)
        var values = engine.values

        var i = 0
        var j = 0
        var k = 0
        while i < n {
            if Double.random(in: 0..<1) < 1.0 / 7.0 {
                aux[k] = values[i]
                engine.writeAux(auxHandle, at: k, value: values[i])
                k += 1
            } else {
                values[j] = values[i]
                engine.setValue(j, values[i])
                j += 1
            }
            i += 1
        }

        for m in 0..<k {
            values[j + m] = aux[m]
            engine.setValue(j + m, aux[m])
        }
        engine.deleteAuxArray(auxHandle)

        for pos in j..<n {
            engine.swap(pos, Int.random(in: pos..<n))
        }
    }
}
