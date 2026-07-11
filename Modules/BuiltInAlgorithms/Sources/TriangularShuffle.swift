import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.TRIANGULAR`. Assigns every position a "level" number via a
/// fractal pattern tied to powers of two (each time the index reaches the next power of two, the
/// level-lookup cursor resets to the start), turns those levels into a genuine index permutation
/// via a stable counting sort over the levels, then gathers the array's values through it.
public struct TriangularShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "triangular")
    public let metadata = ShuffleMetadata(displayName: "Triangular")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }

        var triangle = [Int](repeating: 0, count: n)
        var j = 0
        var k = 2
        var maxLevel = 0
        var i = 1
        while i < n {
            if i == k {
                j = 0
                k *= 2
            }
            triangle[i] = triangle[j] + 1
            if triangle[i] > maxLevel {
                maxLevel = triangle[i]
            }
            i += 1
            j += 1
        }

        var counts = [Int](repeating: 0, count: maxLevel + 1)
        for level in triangle {
            counts[level] += 1
        }
        for c in 1..<counts.count {
            counts[c] += counts[c - 1]
        }
        for pos in stride(from: n - 1, through: 0, by: -1) {
            let level = triangle[pos]
            counts[level] -= 1
            triangle[pos] = counts[level]
        }

        let original = engine.values
        for pos in 0..<n {
            engine.setValue(pos, original[triangle[pos]])
        }
    }
}
