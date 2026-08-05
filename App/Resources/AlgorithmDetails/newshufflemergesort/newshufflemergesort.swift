import Foundation

func multiSwap(_ array: inout [Int], _ i: Int, _ j: Int, _ length: Int) {
    for k in 0 ..< length {
        array.swapAt(i + k, j + k)
    }
}

func rotate(_ array: inout [Int], _ midIn: Int, _ leftLenIn: Int, _ rightLenIn: Int) {
    var mid = midIn
    var leftLen = leftLenIn
    var rightLen = rightLenIn
    while leftLen > 0, rightLen > 0 {
        if leftLen > rightLen {
            multiSwap(&array, mid - rightLen, mid, rightLen)
            mid -= rightLen
            leftLen -= rightLen
        } else {
            multiSwap(&array, mid - leftLen, mid, leftLen)
            mid += leftLen
            rightLen -= leftLen
        }
    }
}

/// Perfect-shuffles a chunk of `size - 1` elements by following the cycles of i -> i*2 mod size.
func shuffleBlock(_ array: inout [Int], _ start: Int, _ size: Int) {
    var i = 1
    while i < size {
        var val = array[start + i - 1]
        var j = (i * 2) % size
        while j != i {
            let nextVal = array[start + j - 1]
            array[start + j - 1] = val
            val = nextVal
            j = (j * 2) % size
        }
        array[start + i - 1] = val
        i *= 3
    }
}

/// A single riffle shuffle only closes into clean cycles at power-of-three sizes, so shuffling
/// happens in power-of-three chunks, rotating the next chunk's tail into place before each one.
func shuffle(_ array: inout [Int], _ startIn: Int, _ end: Int) {
    var start = startIn
    while end - start > 1 {
        let half = (end - start) / 2
        var chunk = 1
        while chunk * 3 - 1 <= 2 * half {
            chunk *= 3
        }
        let tail = (chunk - 1) / 2
        rotate(&array, start + half, half - tail, tail)
        shuffleBlock(&array, start, chunk)
        start += chunk - 1
    }
}

func rotateShuffledEqual(_ array: inout [Int], _ i: Int, _ j: Int, _ size: Int) {
    var k = 0
    while k < size {
        array.swapAt(i + k, j + k)
        k += 2
    }
}

func rotateShuffled(_ array: inout [Int], _ midIn: Int, _ leftLenIn: Int, _ rightLenIn: Int) {
    var mid = midIn
    var leftLen = leftLenIn
    var rightLen = rightLenIn
    while leftLen > 0, rightLen > 0 {
        if leftLen > rightLen {
            rotateShuffledEqual(&array, mid - rightLen, mid, rightLen)
            mid -= rightLen
            leftLen -= rightLen
        } else {
            rotateShuffledEqual(&array, mid - leftLen, mid, leftLen)
            mid += leftLen
            rightLen -= leftLen
        }
    }
}

func rotateShuffledOuter(_ array: inout [Int], _ midIn: Int, _ leftLenIn: Int, _ rightLenIn: Int) {
    var mid = midIn
    var leftLen = leftLenIn
    var rightLen = rightLenIn
    if leftLen > rightLen {
        rotateShuffledEqual(&array, mid - rightLen, mid + 1, rightLen)
        mid -= rightLen
        leftLen -= rightLen
        rotateShuffled(&array, mid, leftLen, rightLen)
    } else {
        rotateShuffledEqual(&array, mid - leftLen, mid + 1, leftLen)
        mid += leftLen + 1
        rightLen -= leftLen
        rotateShuffled(&array, mid, leftLen, rightLen)
    }
}

/// The inverse of shuffleBlock: walks the same cycles, writing each value one step backward.
func unshuffleBlock(_ array: inout [Int], _ start: Int, _ size: Int) {
    var i = 1
    while i < size {
        var prev = i
        let val = array[start + i - 1]
        var j = (i * 2) % size
        while j != i {
            array[start + prev - 1] = array[start + j - 1]
            prev = j
            j = (j * 2) % size
        }
        array[start + prev - 1] = val
        i *= 3
    }
}

func unshuffle(_ array: inout [Int], _ startIn: Int, _ end: Int) {
    var start = startIn
    while end - start > 1 {
        let half = (end - start) / 2
        var chunk = 1
        while chunk * 3 - 1 <= 2 * half {
            chunk *= 3
        }
        let tail = (chunk - 1) / 2
        rotateShuffledOuter(&array, start + 2 * tail, 2 * tail, 2 * half - 2 * tail)
        unshuffleBlock(&array, start, chunk)
        start += chunk - 1
    }
}

func compare3(_ array: [Int], _ i: Int, _ j: Int) -> Int {
    if array[i] < array[j] {
        return -1
    }
    return array[i] == array[j] ? 0 : 1
}

/// Scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in order
/// just advances the scan; a stretch of same-side elements gets un-shuffled back into two short
/// plain runs and rotated into its final position.
func mergeUp(_ array: inout [Int], _ start: Int, _ end: Int, _ fromLeftIn: Bool) {
    var i = start
    var j = i + 1
    var fromLeft = fromLeftIn
    while j < end {
        let cmp = compare3(array, i, j)
        if cmp == -1 || (!fromLeft && cmp == 0) {
            i += 1
            if i == j {
                j += 1
                fromLeft.toggle()
            }
        } else if end - j == 1 {
            rotate(&array, j, j - i, 1)
            break
        } else {
            var run = 0
            if fromLeft {
                while j + 2 * run < end, compare3(array, j + 2 * run, i) != 1 {
                    run += 1
                }
            } else {
                while j + 2 * run < end, compare3(array, j + 2 * run, i) == -1 {
                    run += 1
                }
            }
            j -= 1
            unshuffle(&array, j, j + 2 * run)
            rotate(&array, j, j - i, run)
            i += run + 1
            j += 2 * run + 1
        }
    }
}

func merge(_ array: inout [Int], _ start: Int, _ mid: Int, _ end: Int) {
    if mid - start <= end - mid {
        shuffle(&array, start, end)
        mergeUp(&array, start, end, true)
    } else {
        shuffle(&array, start + 1, end)
        mergeUp(&array, start, end, false)
    }
}

func ceilPow2(_ xIn: Int) -> Int {
    var x = xIn - 1
    var shift = 16
    while shift > 0 {
        x |= x >> shift
        shift >>= 1
    }
    return x + 1
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n >= 2 else { return }

    var subarrayCount = ceilPow2(n)
    while subarrayCount > 1 {
        var i = 0
        while i < subarrayCount {
            let lo = n * i / subarrayCount
            let mid = n * (i + 1) / subarrayCount
            let hi = n * (i + 2) / subarrayCount
            merge(&arr, lo, mid, hi)
            i += 2
        }
        subarrayCount >>= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
