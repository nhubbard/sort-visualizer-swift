func swap(_ arr: inout [Int], _ a: Int, _ b: Int) {
    arr.swapAt(a, b)
}

func multiSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ count: Int) {
    for i in 0 ..< count {
        swap(&arr, a + i, b + i)
    }
}

func rotate(_ arr: inout [Int], _ posArg: Int, _ lenAArg: Int, _ lenBArg: Int) {
    var pos = posArg
    var lenA = lenAArg
    var lenB = lenBArg
    while lenA != 0, lenB != 0 {
        if lenA <= lenB {
            multiSwap(&arr, pos, pos + lenA, lenA)
            pos += lenA
            lenB -= lenA
        } else {
            multiSwap(&arr, pos + (lenA - lenB), pos + lenA, lenB)
            lenA -= lenB
        }
    }
}

func binSearch(_ arr: [Int], _ pos: Int, _ len: Int, _ keyPos: Int, _ isLeft: Bool) -> Int {
    var left = -1
    var right = len
    let key = arr[keyPos]
    while left < right - 1 {
        let mid = left + (right - left) / 2
        let cond = isLeft ? (arr[pos + mid] >= key) : (arr[pos + mid] > key)
        if cond {
            right = mid
        } else {
            left = mid
        }
    }
    return right
}

func mergeWithoutBuffer(_ arr: inout [Int], _ posArg: Int, _ len1Arg: Int, _ len2Arg: Int) {
    var pos = posArg
    var len1 = len1Arg
    var len2 = len2Arg
    if len1 == 0 || len2 == 0 {
        return
    }
    if len1 < len2 {
        while len1 != 0 {
            let loc = binSearch(arr, pos + len1, len2, pos, true)
            if loc != 0 {
                rotate(&arr, pos, len1, loc)
                pos += loc
                len2 -= loc
            }
            if len2 == 0 {
                break
            }
            repeat {
                pos += 1
                len1 -= 1
            } while len1 != 0 && arr[pos] <= arr[pos + len1]
        }
    } else {
        while len2 != 0 {
            let loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
            if loc != len1 {
                rotate(&arr, pos + loc, len1 - loc, len2)
                len1 = loc
            }
            if len1 == 0 {
                break
            }
            repeat {
                len2 -= 1
            } while len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
        }
    }
}

// Guard: a chunk of length <= 1 has nothing to compare. The original source skips this
// check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
// leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
func insertionSortChunk(_ arr: inout [Int], _ a: Int, _ b: Int) {
    if b - a <= 1 {
        return
    }
    var i = a + 1
    let descending = arr[i - 1] > arr[i]
    i += 1
    if descending {
        while i < b, arr[i - 1] > arr[i] {
            i += 1
        }
        var lo = a
        var hi = i - 1
        while lo < hi {
            swap(&arr, lo, hi)
            lo += 1
            hi -= 1
        }
    } else {
        while i < b, arr[i - 1] <= arr[i] {
            i += 1
        }
    }
    while i < b {
        let current = arr[i]
        var pos = i - 1
        while pos >= a, arr[pos] > current {
            arr[pos + 1] = arr[pos]
            pos -= 1
        }
        arr[pos + 1] = current
        i += 1
    }
}

func lazyStableSort(_ arr: inout [Int], _ pos: Int, _ len: Int) {
    var dist = 0
    while dist + 16 < len {
        insertionSortChunk(&arr, pos + dist, pos + dist + 16)
        dist += 16
    }
    if dist < len {
        insertionSortChunk(&arr, pos + dist, pos + len)
    }

    var part = 16
    while part < len {
        var left = 0
        let right = len - 2 * part
        while left <= right {
            mergeWithoutBuffer(&arr, pos + left, part, part)
            left += 2 * part
        }
        let rest = len - left
        if rest > part {
            mergeWithoutBuffer(&arr, pos + left, part, rest - part)
        }
        part *= 2
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    lazyStableSort(&arr, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
