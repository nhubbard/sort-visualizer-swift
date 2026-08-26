let insertionThreshold = 24

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

/// Dual-pivot partition of arr[start..<end]. `scratch` is a fixed index outside this range,
/// borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
/// the boundary between the low region and everything at or above the smaller of the two pivots.
func partition(_ arr: inout [Int], _ start: Int, _ endIn: Int, _ scratch: Int) -> Int {
    var end = endIn
    let m1 = (start + start + end) / 3
    let m2 = (start + end + end) / 3

    if arr[m1] > arr[m2] {
        arr.swapAt(m1, start)
        end -= 1
        arr.swapAt(m2, end)
    } else {
        arr.swapAt(m2, start)
        end -= 1
        arr.swapAt(m1, end)
    }

    var low = start
    var high = end
    // Reversed from the usual low/high naming: after the swaps above, `start` holds the larger
    // of the two chosen medians and `end` the smaller. Neither position moves again until the
    // closing rotation below, so their values are safe to hold onto directly.
    let pivotMax = arr[start]
    let pivotMin = arr[end]

    var k = low + 1
    while k < high {
        if arr[k] < pivotMin {
            low += 1
            arr.swapAt(k, low)
        } else if arr[k] >= pivotMax {
            repeat {
                high -= 1
            } while high > k && arr[high] >= pivotMax
            arr.swapAt(k, high)

            if arr[k] < pivotMin {
                low += 1
                arr.swapAt(k, low)
            }
        }
        k += 1
    }

    arr.swapAt(start, low)
    // Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
    // `scratch` moves to `high`, and whatever was at `high` moves to `end`.
    let displaced = arr[end]
    arr[end] = arr[high]
    arr[high] = arr[scratch]
    arr[scratch] = displaced

    return low
}

/// Sorts arr[start..<end] in place with no recursion: a single loop processes one segment at a
/// time, shrinking and partitioning it down to `insertionThreshold` elements, finishing with
/// `binaryInsertionSort`, then advancing past it to the next segment.
func quickSort(_ arr: inout [Int], _ start: Int, _ endIn: Int) {
    var end = endIn

    // Move every copy of this range's maximum value to the very end first. Those elements are
    // already correctly placed relative to everything else, so the rest of the algorithm never
    // has to look at them again — and the boundary in front of them becomes fixed scratch space
    // `partition` can borrow from.
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
    // refresh one of its two candidates, since reusing them would just compare equal again.
    var reuseMedianCandidates = true

    while true {
        while segmentEnd - a > insertionThreshold {
            if !reuseMedianCandidates {
                arr.swapAt(a, (a + a + segmentEnd) / 3)
            }
            segmentEnd = partition(&arr, a, segmentEnd, tail)
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

        reuseMedianCandidates = true
        while a < segmentEnd, arr[a - 1] == arr[a] {
            reuseMedianCandidates = false
            a += 1
        }
        if a == segmentEnd {
            reuseMedianCandidates = true
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
