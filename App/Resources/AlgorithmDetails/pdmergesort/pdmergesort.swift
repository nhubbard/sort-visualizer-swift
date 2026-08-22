func reverseRun(_ arr: inout [Int], _ loIn: Int, _ hiIn: Int) {
    var lo = loIn
    var hi = hiIn
    while lo < hi {
        arr.swapAt(lo, hi)
        lo += 1
        hi -= 1
    }
}

/// Finds the maximal run starting at indexIn (every adjacent step in the same
/// direction), reversing it in place if that direction was descending.
/// Returns the index where the next run starts, or -1 if this was the last
/// run.
func identifyRun(_ arr: inout [Int], _ indexIn: Int, _ n: Int) -> Int {
    if indexIn >= n - 1 {
        return -1
    }
    let startIndex = indexIn
    var index = indexIn
    let ascending = arr[index] <= arr[index + 1]
    index += 1
    while index < n - 1 {
        let stepAscending = arr[index] <= arr[index + 1]
        if stepAscending != ascending {
            break
        }
        index += 1
    }
    if !ascending {
        reverseRun(&arr, startIndex, index)
    }
    return index >= n - 1 ? -1 : index + 1
}

/// Merges arr[start..<mid] with arr[mid..<end] by copying the left run into a
/// scratch buffer and merging forward from the low end.
func mergeUp(_ arr: inout [Int], _ start: Int, _ mid: Int, _ end: Int, _ buffer: inout [Int]) {
    for i in 0 ..< (mid - start) {
        buffer[i] = arr[start + i]
    }
    var bufferPointer = 0
    var left = start
    var right = mid
    while left < right, right < end {
        if buffer[bufferPointer] <= arr[right] {
            arr[left] = buffer[bufferPointer]
            bufferPointer += 1
        } else {
            arr[left] = arr[right]
            right += 1
        }
        left += 1
    }
    while left < right {
        arr[left] = buffer[bufferPointer]
        bufferPointer += 1
        left += 1
    }
}

/// Merges arr[start..<mid] with arr[mid..<end] by copying the right run into a
/// scratch buffer and merging backward from the high end.
func mergeDown(_ arr: inout [Int], _ start: Int, _ mid: Int, _ end: Int, _ buffer: inout [Int]) {
    for i in 0 ..< (end - mid) {
        buffer[i] = arr[mid + i]
    }
    var bufferPointer = end - mid - 1
    var left = mid - 1
    var right = end - 1
    while right > left, left >= start {
        if buffer[bufferPointer] >= arr[left] {
            arr[right] = buffer[bufferPointer]
            bufferPointer -= 1
        } else {
            arr[right] = arr[left]
            left -= 1
        }
        right -= 1
    }
    while right > left {
        arr[right] = buffer[bufferPointer]
        bufferPointer -= 1
        right -= 1
    }
}

/// Picks whichever of mergeUp/mergeDown needs the smaller scratch copy.
func mergeRuns(_ arr: inout [Int], _ leftStart: Int, _ rightStart: Int, _ end: Int, _ buffer: inout [Int]) {
    if end - rightStart < rightStart - leftStart {
        mergeDown(&arr, leftStart, rightStart, end, &buffer)
    } else {
        mergeUp(&arr, leftStart, rightStart, end, &buffer)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n >= 2 else { return }

    var runs: [Int] = []
    var lastRun = 0
    while lastRun != -1 {
        runs.append(lastRun)
        lastRun = identifyRun(&arr, lastRun, n)
    }

    var buffer = [Int](repeating: 0, count: n)
    var runCount = runs.count
    while runCount > 1 {
        var i = 0
        while i < runCount - 1 {
            let end = i + 2 >= runCount ? n : runs[i + 2]
            mergeRuns(&arr, runs[i], runs[i + 1], end, &buffer)
            i += 2
        }

        runs = stride(from: 0, to: runCount, by: 2).map { runs[$0] }
        runCount = runs.count
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
