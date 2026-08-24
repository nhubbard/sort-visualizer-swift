import Foundation

func circleSortRoutine(_ array: inout [Int], _ lo: Int, _ hi: Int, _ end: Int) -> Int {
    if lo == hi {
        return 0
    }
    let low = lo
    let high = hi
    let mid = (hi - lo) / 2
    var swapCount = 0
    var lo = lo
    var hi = hi
    while lo < hi {
        if hi < end && array[lo] > array[hi] {
            array.swapAt(lo, hi)
            swapCount += 1
        }
        lo += 1
        hi -= 1
    }
    swapCount += circleSortRoutine(&array, low, low + mid, end)
    if low + mid + 1 < end {
        swapCount += circleSortRoutine(&array, low + mid + 1, high, end)
    }
    return swapCount
}

func binaryInsertionSort(_ array: inout [Int], _ end: Int) {
    for i in 1 ..< end {
        let value = array[i]
        var lo = 0
        var hi = i
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            if value < array[mid] {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        var j = i
        while j > lo {
            array[j] = array[j - 1]
            j -= 1
        }
        array[lo] = value
    }
}

func sort(_ array: inout [Int]) {
    let end = array.count
    if end <= 1 {
        return
    }
    var n = 1
    var threshold = 0
    while n < end {
        n <<= 1
        threshold += 1
    }
    threshold /= 2

    var iterations = 0
    while true {
        iterations += 1
        if iterations >= threshold {
            binaryInsertionSort(&array, end)
            return
        }
        if circleSortRoutine(&array, 0, n - 1, end) == 0 {
            return
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
