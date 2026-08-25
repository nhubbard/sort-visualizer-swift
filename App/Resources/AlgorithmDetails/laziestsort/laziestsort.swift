import Foundation

func binaryInsertionSort(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    var i = lo + 1
    while i < hi {
        let key = arr[i]
        var left = lo
        var right = i
        while left < right {
            let mid = (left + right) / 2
            if arr[mid] <= key {
                left = mid + 1
            } else {
                right = mid
            }
        }
        var j = i
        while j > left {
            arr[j] = arr[j - 1]
            j -= 1
        }
        arr[left] = key
        i += 1
    }
}

func swapRange(_ arr: inout [Int], _ a: Int, _ b: Int, _ length: Int) {
    for i in 0 ..< length {
        arr.swapAt(a + i, b + i)
    }
}

/// Swaps the two adjacent blocks arr[lo ..< mid] and arr[mid ..< hi] so their order is
/// reversed, using no auxiliary storage: the smaller of the two remaining pieces is
/// always swapped whole against an equal-sized piece of the other, which shrinks one
/// piece to nothing a little at a time until both are exhausted.
func rotate(_ arr: inout [Int], _ lo: Int, _ mid: Int, _ hi: Int) {
    var i = mid - lo
    var j = hi - mid
    if i == 0 || j == 0 {
        return
    }
    while i != j {
        if i < j {
            swapRange(&arr, mid - i, mid + j - i, i)
            j -= i
        } else {
            swapRange(&arr, mid - i, mid, j)
            i -= j
        }
    }
    swapRange(&arr, mid - i, mid, i)
}

/// Finds the first index in [lo, hi) whose element is not less than value, by doubling
/// the step size until it overshoots and then binary-searching the resulting bracket,
/// rather than scanning one element at a time. Assumes arr[lo] < value.
func gallop(_ arr: [Int], _ lo: Int, _ hi: Int, _ value: Int) -> Int {
    var left = lo
    var step = 1
    var right = lo + step
    while right < hi, arr[right] < value {
        left = right
        step *= 2
        right = lo + step
    }
    right = min(right, hi)
    while right - left > 1 {
        let mid = (left + right) / 2
        if arr[mid] < value {
            left = mid
        } else {
            right = mid
        }
    }
    return right
}

/// Merges the sorted run arr[lo ..< mid] into the sorted run arr[mid ..< hi] in place.
/// `left` tracks the first not-yet-placed element of the left run, and `right` tracks
/// the start of the not-yet-consumed remainder of the right run.
func merge(_ arr: inout [Int], _ lo: Int, _ mid: Int, _ hi: Int) {
    var left = lo
    var right = mid
    while left < right, right < hi {
        if arr[left] <= arr[right] {
            left += 1
        } else {
            let boundary = gallop(arr, right, hi, arr[left])
            rotate(&arr, left, right, boundary)
            left += boundary - right
            right = boundary
        }
    }
}

func integerSqrt(_ n: Int) -> Int {
    var r = Int(Double(n).squareRoot())
    while (r + 1) * (r + 1) <= n {
        r += 1
    }
    while r * r > n {
        r -= 1
    }
    return r
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n <= 16 {
        binaryInsertionSort(&arr, 0, n)
        return
    }

    let blockSize = max(16, integerSqrt(n))
    var low = 0
    while low < n {
        binaryInsertionSort(&arr, low, min(low + blockSize, n))
        low += blockSize
    }

    // Merge blocks back to front: the already-sorted run always starts at
    // mergedStart, and each step folds the block immediately before it into that run.
    let numBlocks = (n + blockSize - 1) / blockSize
    var mergedStart = (numBlocks - 1) * blockSize
    for i in stride(from: numBlocks - 2, through: 0, by: -1) {
        let leftStart = i * blockSize
        merge(&arr, leftStart, mergedStart, n)
        mergedStart = leftStart
    }
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12,
]
sort(&array)
print(array)
