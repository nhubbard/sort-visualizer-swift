import Foundation

func circleSortRoutine(_ array: inout [Int], _ length: Int, _ end: Int) -> Int {
    var swapCount = 0
    var gap = length / 2
    while gap > 0 {
        var start = 0
        while start + gap < end {
            var low = start
            var high = start + 2 * gap - 1
            while low < high {
                if high < end && array[low] > array[high] {
                    array.swapAt(low, high)
                    swapCount += 1
                }
                low += 1
                high -= 1
            }
            start += 2 * gap
        }
        gap /= 2
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
        if circleSortRoutine(&array, n, end) == 0 {
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
