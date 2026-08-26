let insertionThreshold = 16

/// Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends up at `start`,
/// ready to serve as partition's pivot.
func medianOfThree(_ arr: inout [Int], _ start: Int, _ end: Int) {
    let mid = start + (end - 1 - start) / 2
    if arr[start] > arr[mid] {
        arr.swapAt(start, mid)
    }
    if arr[mid] > arr[end - 1] {
        arr.swapAt(mid, end - 1)
        if arr[start] > arr[mid] {
            return
        }
    }
    arr.swapAt(start, mid)
}

/// Classic two-pointer Hoare partition against the pivot medianOfThree just placed at `start`.
/// Returns the pivot's final resting index.
func partition(_ arr: inout [Int], _ start: Int, _ end: Int) -> Int {
    medianOfThree(&arr, start, end)
    let pivot = arr[start]
    var i = start
    var j = end

    while true {
        i += 1
        while i < j && arr[i] < pivot {
            i += 1
        }
        j -= 1
        while j >= i && arr[j] >= pivot {
            j -= 1
        }
        if i < j {
            arr.swapAt(i, j)
        } else {
            arr.swapAt(start, j)
            return j
        }
    }
}

/// Finds where the value at `targetIndex` belongs among arr[start..<end], ties resolving toward
/// the front (a plain lower-bound binary search).
func lowerBoundIndex(_ arr: [Int], _ start: Int, _ end: Int, _ targetIndex: Int) -> Int {
    var lo = start
    var hi = end
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if arr[targetIndex] <= arr[mid] {
            hi = mid
        } else {
            lo = mid + 1
        }
    }
    return lo
}

/// Sorts arr[start..<end] in place using a plain binary-search insertion sort — the base case
/// once a segment shrinks small enough that further partitioning isn't worth it.
func binaryInsertionSort(_ arr: inout [Int], _ start: Int, _ end: Int) {
    var i = start
    while i < end {
        let value = arr[i]
        var lo = start
        var hi = i
        while lo < hi {
            let mid = lo + (hi - lo) / 2
            if value < arr[mid] {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        var j = i - 1
        while j >= lo {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[lo] = value
        i += 1
    }
}

/// Sorts arr[start..<end] in place with no recursion: a single loop processes one segment at a
/// time, shrinking and partitioning it down to `insertionThreshold` elements, finishing with
/// `binaryInsertionSort`, then advancing past it to the next segment.
func quickSort(_ arr: inout [Int], _ start: Int, _ endIn: Int) {
    var end = endIn

    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again — and the boundary in front of them becomes the fixed resting
    // place `partition` sends each finished pivot out to.
    var maxValue = arr[start]
    var i = start + 1
    while i < end {
        if arr[i] > maxValue {
            maxValue = arr[i]
        }
        i += 1
    }

    var tail = end
    i = end - 1
    while i >= start {
        if arr[i] == maxValue {
            tail -= 1
            arr.swapAt(i, tail)
        }
        i -= 1
    }

    var a = start
    var segmentEnd = tail
    // False right after skipping a run of duplicates below means the next median-of-three should
    // refresh its candidates, since reusing them would just compare equal again.
    var refreshMedian = true

    while true {
        while segmentEnd - a > insertionThreshold {
            if refreshMedian {
                medianOfThree(&arr, a, segmentEnd)
            }
            let pivotIndex = partition(&arr, a, segmentEnd)
            arr.swapAt(pivotIndex, tail)
            segmentEnd = pivotIndex
        }
        binaryInsertionSort(&arr, a, segmentEnd)

        a = segmentEnd + 1
        if a >= tail {
            if a - 1 < tail {
                arr.swapAt(a - 1, tail)
            }
            return
        }

        segmentEnd = lowerBoundIndex(arr, a, tail, a - 1)
        arr.swapAt(a - 1, tail)

        refreshMedian = true
        while a < segmentEnd, arr[a - 1] == arr[a] {
            refreshMedian = false
            a += 1
        }
        if a == segmentEnd {
            refreshMedian = true
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    quickSort(&arr, 0, n)
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
    21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
]
sort(&array)
print(array)
