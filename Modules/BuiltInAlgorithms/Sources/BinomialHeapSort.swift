import AlgorithmKit
import SortEngineKit

public struct BinomialHeapSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "binomialheapsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Binomial Heap Sort",
        category: .selection,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(1)",
        iconName: "b.square.fill"
    )
    public init() {}

    /// ArrayV's own arithmetic is entirely 1-indexed (`array[x - 1]` everywhere) and leans on bit
    /// tricks over that 1-indexed position rather than an explicit tree structure — a binomial
    /// heap's node `x`'s "parent-ward" neighbors are found by clearing successively higher set
    /// bits of `x`. This translates the index bookkeeping line-for-line (still 1-indexed
    /// internally, only ever converted to a 0-indexed `engine` call at the point of an actual
    /// compare/swap) rather than re-deriving the bit arithmetic from a cleaner 0-indexed model,
    /// since faithfulness to the exact traversal order matters more here than tidiness.
    ///
    /// **Phase 1** (`index` stepping by 2): builds the binomial-heap structure — for each even
    /// `index`, repeatedly finds the largest value among `index` and its "binomial siblings"
    /// (found by clearing the lowest set bit not yet cleared) and bubbles it up via swap, stopping
    /// once a full pass finds nothing bigger.
    ///
    /// **Phase 2** (`index` counting down from `n`): extracts the max at the current root by
    /// walking the set bits of `index` from lowest to highest (each one names a subtree root to
    /// compare), then — if a bigger node was found — repeats the same bubble-up as phase 1,
    /// starting from that node, to restore the structure before moving to the next `index`.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var index = 2
        while index <= n {
            var maxNode = index
            var focus: Int
            repeat {
                focus = maxNode
                var depth = 1
                while (focus & depth) == 0 {
                    if engine.compare(focus - depth - 1, maxNode - 1, by: (>)) {
                        maxNode = focus - depth
                    }
                    depth *= 2
                }
                if focus != maxNode {
                    engine.swap(focus - 1, maxNode - 1)
                }
            } while focus != maxNode
            index += 2
        }

        index = n
        while index > 2 {
            var maxNode = index
            var focus = index
            var depth = 1
            while focus != 0 {
                if (focus & depth) != 0 {
                    if engine.compare(focus - 1, maxNode - 1, by: (>)) {
                        maxNode = focus
                    }
                    focus -= depth
                }
                depth *= 2
            }

            if maxNode != index {
                focus = index
                repeat {
                    engine.swap(focus - 1, maxNode - 1)
                    focus = maxNode
                    var innerDepth = 1
                    while (focus & innerDepth) == 0 {
                        if engine.compare(focus - innerDepth - 1, maxNode - 1, by: (>)) {
                            maxNode = focus - innerDepth
                        }
                        innerDepth *= 2
                    }
                } while focus != maxNode
            }
            index -= 1
        }
    }
}
