func multiSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ count: Int) {
    for i in 0 ..< count {
        arr.swapAt(a + i, b + i)
    }
}

func rotate(_ arr: inout [Int], _ pos: Int, _ lenA: Int, _ lenB: Int) {
    var p = pos
    var la = lenA
    var lb = lenB
    while la != 0, lb != 0 {
        if la <= lb {
            multiSwap(&arr, p, p + la, la)
            p += la
            lb -= la
        } else {
            multiSwap(&arr, p + (la - lb), p + la, lb)
            la -= lb
        }
    }
}

func binSearch(_ arr: [Int], _ pos: Int, _ len: Int, _ keyPos: Int, _ isLeft: Bool) -> Int {
    var left = 0
    var right = len
    while left < right {
        let mid = left + (right - left) / 2
        let cond = isLeft ? arr[pos + mid] < arr[keyPos] : arr[pos + mid] <= arr[keyPos]
        if cond {
            left = mid + 1
        } else {
            right = mid
        }
    }
    return left
}

func mergeWithoutBuffer(_ arr: inout [Int], _ start: Int, _ leftLength: Int, _ rightLength: Int) {
    var pos = start
    var len1 = leftLength
    var len2 = rightLength
    if len1 < len2 {
        while len1 != 0 {
            let loc = binSearch(arr, pos + len1, len2, pos, true)
            if loc != 0 { rotate(&arr, pos, len1, loc); pos += loc; len2 -= loc }
            if len2 == 0 { break }
            repeat { pos += 1; len1 -= 1 } while len1 != 0 && arr[pos] <= arr[pos + len1]
        }
    } else {
        while len2 != 0 {
            let loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
            if loc != len1 { rotate(&arr, pos + loc, len1 - loc, len2); len1 = loc }
            if len1 == 0 { break }
            repeat { len2 -= 1 } while len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var dist = 1
    while dist < n {
        if arr[dist - 1] > arr[dist] {
            arr.swapAt(dist - 1, dist)
        }
        dist += 2
    }
    var part = 2
    while part < n {
        var left = 0
        let right = n - 2 * part
        while left <= right {
            mergeWithoutBuffer(&arr, left, part, part)
            left += 2 * part
        }
        let rest = n - left
        if rest > part {
            mergeWithoutBuffer(&arr, left, part, rest - part)
        }
        part *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
