import Foundation

func sort(_ arr: inout [Int]) {
    let n = arr.count
    let sizeThreshold = 16

    func medianOf3(_ left: Int, _ mid: Int, _ right: Int) -> Int {
        if !(arr[left] >= arr[right]) {
            arr.swapAt(left, right)
        }
        if !(arr[left] >= arr[mid]) {
            arr.swapAt(left, mid)
        }
        if !(arr[mid] >= arr[right]) {
            arr.swapAt(mid, right)
        }
        return mid
    }

    func partition(_ lo: Int, _ hi: Int, _ pivotValue: Int) -> Int {
        var i = lo
        var j = hi
        while true {
            while arr[i] < pivotValue {
                i += 1
            }
            j -= 1
            while pivotValue < arr[j] {
                j -= 1
            }
            if !(i < j) {
                return i
            }
            arr.swapAt(i, j)
            i += 1
        }
    }

    func heapSortRange(_ lo: Int, _ hi: Int) {
        let size = hi - lo

        func siftDown(_ rootStart: Int, _ rangeSize: Int) {
            var root = rootStart
            while true {
                var largest = root
                let left = 2 * root + 1
                let right = 2 * root + 2
                if left < rangeSize, arr[lo + largest] < arr[lo + left] {
                    largest = left
                }
                if right < rangeSize, arr[lo + largest] < arr[lo + right] {
                    largest = right
                }
                if largest == root {
                    break
                }
                arr.swapAt(lo + root, lo + largest)
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
            arr.swapAt(lo, lo + end)
            siftDown(0, end)
            end -= 1
        }
    }

    func introsortLoop(_ lo: Int, _ hiStart: Int, _ depthLimitStart: Int) {
        var hi = hiStart
        var depthLimit = depthLimitStart
        while hi - lo > sizeThreshold {
            if depthLimit == 0 {
                heapSortRange(lo, hi)
                return
            }
            depthLimit -= 1
            let mid = lo + (hi - lo) / 2
            let pivotIndex = medianOf3(lo, mid, hi - 1)
            let pivotValue = arr[pivotIndex]
            let p = partition(lo, hi, pivotValue)
            introsortLoop(p, hi, depthLimit)
            hi = p
        }
    }

    func insertionSort(_ start: Int, _ end: Int) {
        var i = start + 1
        while i < end {
            var j = i
            while j > start, arr[j] < arr[j - 1] {
                arr.swapAt(j - 1, j)
                j -= 1
            }
            i += 1
        }
    }

    func floorLog2(_ a: Int) -> Int {
        return Int(floor(log(Double(a)) / log(2.0)))
    }

    introsortLoop(0, n, 2 * floorLog2(n))
    insertionSort(0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
