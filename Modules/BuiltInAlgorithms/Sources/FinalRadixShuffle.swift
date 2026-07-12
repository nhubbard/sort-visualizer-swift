import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.FINAL_RADIX`. Splits the array (truncated to an even length —
/// a trailing odd element is left untouched) into its first and second halves, then interleaves
/// them back together as second, first, second, first, ... — undoing the last un-interleave pass
/// a 2-bucket LSD radix sort would need to finish.
public struct FinalRadixShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "finalradix")
    public let metadata = ShuffleMetadata(displayName: "Final Radix")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let evenLength = engine.count - engine.count % 2
        guard evenLength > 0 else { return }
        let mid = evenLength / 2
        let firstHalf = Array(engine.values[0..<mid])

        var i = mid
        var j = 0
        while i < evenLength {
            let secondHalfElement = engine.values[i]
            engine.setValue(j, secondHalfElement)
            engine.setValue(j + 1, firstHalf[i - mid])
            i += 1
            j += 2
        }
    }
}
