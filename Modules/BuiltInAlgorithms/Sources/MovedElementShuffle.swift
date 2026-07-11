import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.MOVED_ELEMENT`. Picks two random positions and relocates the
/// element at `start` to `dest`, shifting everything between them over by one to make room —
/// ArrayV does this via a block-rotation helper (`IndexedRotations.holyGriesMills`); a plain chain
/// of adjacent swaps walking the element from `start` to `dest` produces the identical final
/// arrangement.
public struct MovedElementShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "movedelement")
    public let metadata = ShuffleMetadata(displayName: "Shifted Element")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        let start = Int.random(in: 0..<n)
        let dest = Int.random(in: 0..<n)
        if dest < start {
            for i in stride(from: start, to: dest, by: -1) {
                engine.swap(i, i - 1)
            }
        } else {
            for i in stride(from: start, to: dest, by: 1) {
                engine.swap(i, i + 1)
            }
        }
    }
}
