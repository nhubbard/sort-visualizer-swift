import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.ORGAN`. Every even-indexed element moves to the front, in
/// original order; every odd-indexed element moves to the back, in *reverse* order — like folding
/// the array's odd "half" backward over the even "half", the way a pipe organ's pipes step up then
/// back down.
public struct OrganShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "organ")
    public let metadata = ShuffleMetadata(displayName: "Pipe Organ")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        var temp = [Int](repeating: 0, count: n)

        var j = 0
        var i = 0
        while i < n {
            temp[j] = engine.values[i]
            j += 1
            i += 2
        }

        j = n
        i = 1
        while i < n {
            j -= 1
            temp[j] = engine.values[i]
            i += 2
        }

        for k in 0..<n {
            engine.setValue(k, temp[k])
        }
    }
}
