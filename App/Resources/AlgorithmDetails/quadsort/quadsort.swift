let insertionRun = 4

func insertionSortRange(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    var i = lo + 1
    while i < hi {
        let key = arr[i]
        var j = i - 1
        while j >= lo, arr[j] > key {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[j + 1] = key
        i += 1
    }
}

/// Merges the two equal-length sorted runs source[lo..<lo+runLength] and
/// source[lo+runLength..<lo+2*runLength] into dest, filling from both ends toward the middle at
/// once instead of scanning front to back alone.
func parityMerge(_ source: [Int], _ lo: Int, _ runLength: Int, _ dest: inout [Int]) {
    var left = lo
    var right = lo + runLength
    var leftEnd = lo + runLength - 1
    var rightEnd = lo + 2 * runLength - 1
    var front = lo
    var back = lo + 2 * runLength - 1

    for _ in 0 ..< runLength {
        if source[left] <= source[right] {
            dest[front] = source[left]
            left += 1
        } else {
            dest[front] = source[right]
            right += 1
        }
        front += 1

        if source[leftEnd] > source[rightEnd] {
            dest[back] = source[leftEnd]
            leftEnd -= 1
        } else {
            dest[back] = source[rightEnd]
            rightEnd -= 1
        }
        back -= 1
    }
}

func mergeRange(_ source: [Int], _ lo: Int, _ mid: Int, _ hi: Int, _ dest: inout [Int]) {
    var left = lo
    var right = mid
    var out = lo
    while left < mid, right < hi {
        if source[left] <= source[right] {
            dest[out] = source[left]
            left += 1
        } else {
            dest[out] = source[right]
            right += 1
        }
        out += 1
    }
    while left < mid {
        dest[out] = source[left]
        left += 1
        out += 1
    }
    while right < hi {
        dest[out] = source[right]
        right += 1
        out += 1
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    var buffer = arr

    var lo = 0
    while lo < n {
        insertionSortRange(&arr, lo, min(lo + insertionRun, n))
        lo += insertionRun
    }

    var runLength = insertionRun
    while runLength < n {
        lo = 0
        while lo < n {
            let mid = min(lo + runLength, n)
            let hi = min(lo + runLength * 2, n)
            if mid - lo == runLength, hi - mid == runLength {
                parityMerge(arr, lo, runLength, &buffer)
            } else if mid < hi {
                mergeRange(arr, lo, mid, hi, &buffer)
            } else {
                for i in lo ..< mid {
                    buffer[i] = arr[i]
                }
            }
            lo += runLength * 2
        }
        arr = buffer
        runLength *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
