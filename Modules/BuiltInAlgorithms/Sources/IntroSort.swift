import AlgorithmKit
import Foundation
import SortEngineKit

public struct IntroSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "introsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Intro Sort",
        category: .logarithmic,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(log n)",
        iconName: "square.stack.3d.up"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        let sizeThreshold = 16

        func medianOf3(_ left: Int, _ mid: Int, _ right: Int) -> Int {
            if !engine.compare(right, left) {
                engine.swap(left, right)
            }
            if !engine.compare(mid, left) {
                engine.swap(mid, left)
            }
            if !engine.compare(right, mid) {
                engine.swap(right, mid)
            }
            return mid
        }

        func partition(_ lo: Int, _ hi: Int, _ pivotValue: Int) -> Int {
            var i = lo, j = hi
            while true {
                while engine.values[i] < pivotValue { i += 1 }
                j -= 1
                while pivotValue < engine.values[j] { j -= 1 }
                if !(i < j) { return i }
                engine.swap(i, j)
                i += 1
            }
        }

        func heapSortRange(_ lo: Int, _ hi: Int) {
            let size = hi - lo

            func siftDown(_ root: Int, _ rangeSize: Int) {
                var root = root
                while true {
                    var largest = root
                    let left = 2 * root + 1
                    let right = 2 * root + 2
                    if left < rangeSize && !engine.compare(lo + largest, lo + left) { largest = left }
                    if right < rangeSize && !engine.compare(lo + largest, lo + right) { largest = right }
                    if largest == root { break }
                    engine.swap(lo + root, lo + largest)
                    root = largest
                }
            }

            var i = size / 2 - 1
            while i >= 0 {
                siftDown(i, size)
                i -= 1
            }
            var end = size - 1
            while end > 0 {
                engine.swap(lo, lo + end)
                siftDown(0, end)
                end -= 1
            }
        }

        func introsortLoop(_ lo: Int, _ hi: Int, _ depthLimit: Int) {
            var hi = hi
            var depthLimit = depthLimit
            while hi - lo > sizeThreshold {
                if depthLimit == 0 {
                    heapSortRange(lo, hi)
                    return
                }
                depthLimit -= 1
                let mid = lo + (hi - lo) / 2
                let pivotIndex = medianOf3(lo, mid, hi - 1)
                let pivotValue = engine.values[pivotIndex]
                let p = partition(lo, hi, pivotValue)
                introsortLoop(p, hi, depthLimit)
                hi = p
            }
        }

        func insertionSort(_ start: Int, _ end: Int) {
            var i = start + 1
            while i < end {
                var j = i
                while j > start && !engine.compare(j, j - 1) {
                    engine.swap(j - 1, j)
                    j -= 1
                }
                i += 1
            }
        }

        func floorLog2(_ a: Int) -> Int {
            Int((log(Double(a)) / log(2.0)).rounded(.down))
        }

        introsortLoop(0, n, 2 * floorLog2(n))
        insertionSort(0, n)
    }
}
