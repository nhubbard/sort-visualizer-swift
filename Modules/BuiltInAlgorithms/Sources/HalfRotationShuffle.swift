import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.HALF_ROTATION`. Rotates the array by half its length: for an
/// even-length array this is just swapping each element in the first half with its counterpart in
/// the second half; for odd lengths, the exact middle element has nowhere to pair with, so it's
/// carried aside and reinserted once every other element has shifted.
public struct HalfRotationShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "halfrotation")
    public let metadata = ShuffleMetadata(displayName: "Half Rotation")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var a = 0
        var m = (n + 1) / 2

        if n.isMultiple(of: 2) {
            while m < n {
                engine.swap(a, m)
                a += 1
                m += 1
            }
        } else {
            let carried = engine.values[a]
            while m < n {
                engine.setValue(a, engine.values[m])
                a += 1
                engine.setValue(m, engine.values[a])
                m += 1
            }
            engine.setValue(a, carried)
        }
    }
}
