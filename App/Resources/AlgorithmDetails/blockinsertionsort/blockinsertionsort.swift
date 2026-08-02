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

func findRun(_ arr: inout [Int], _ a: Int, _ b: Int) -> Int {
    var i = a + 1
    if i == b {
        return i
    }
    if arr[i - 1] > arr[i] {
        i += 1
        while i < b && arr[i - 1] > arr[i] {
            i += 1
        }
        var lo = a
        var hi = i - 1
        while lo < hi {
            arr.swapAt(lo, hi)
            lo += 1
            hi -= 1
        }
    } else {
        i += 1
        while i < b && arr[i - 1] <= arr[i] {
            i += 1
        }
    }
    return i
}

func insert1(_ arr: inout [Int], _ a: Int, _ l: Int) {
    let tmp = arr[l]
    var i = l - 1
    while i >= a, arr[i] > tmp {
        arr[i + 1] = arr[i]
        i -= 1
    }
    arr[i + 1] = tmp
}

func insert2(_ arr: inout [Int], _ a: Int, _ l: Int, _ r: Int) {
    let tmpL = arr[l]
    let tmpR = arr[r]
    var i = l - 1
    while i >= a, arr[i] > tmpR {
        arr[i + 2] = arr[i]
        i -= 1
    }
    arr[i + 2] = tmpR
    while i >= a, arr[i] > tmpL {
        arr[i + 1] = arr[i]
        i -= 1
    }
    arr[i + 1] = tmpL
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var i = findRun(&arr, 0, n)
    while i < n {
        let j = findRun(&arr, i, n)
        let len = j - i
        if len == 1 {
            insert1(&arr, 0, i)
        } else if len == 2 {
            insert2(&arr, 0, i, i + 1)
        } else {
            mergeWithoutBuffer(&arr, 0, i, len)
        }
        i = j
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
