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

func mergeWithoutBuffer(_ arr: inout [Int], _ pos: Int, _ len1: Int, _ len2: Int) {
    if len1 == 0 || len2 == 0 {
        return
    }
    if len1 == 1 {
        let loc = binSearch(arr, pos + 1, len2, pos, true)
        rotate(&arr, pos, 1, loc)
        return
    }
    if len2 == 1 {
        let loc = binSearch(arr, pos, len1, pos + len1, false)
        rotate(&arr, pos + loc, len1 - loc, 1)
        return
    }
    let mid1 = len1 / 2
    let loc = binSearch(arr, pos + len1, len2, pos + mid1, true)
    rotate(&arr, pos + mid1, len1 - mid1, loc)
    mergeWithoutBuffer(&arr, pos, mid1, loc)
    mergeWithoutBuffer(&arr, pos + mid1 + loc, len1 - mid1, len2 - loc)
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
