func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n >= 2 else { return }
    let radixBase = 10

    /// Extracts the digit at `place` (0 = ones place) from `value`, in radixBase.
    func digitAt(_ value: Int, _ place: Int) -> Int {
        var divisor = 1
        for _ in 0 ..< place {
            divisor *= radixBase
        }
        return (value / divisor) % radixBase
    }

    /// Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
        for i in 0 ..< len {
            arr.swapAt(a + i, b + i)
        }
    }

    /// Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
    /// using only block-swaps -- no auxiliary buffer.
    func rotateBlock(_ a: Int, _ m: Int, _ b: Int) {
        var a = a
        var m = m
        var b = b
        var l = m - a
        var r = b - m
        while l > 0, r > 0 {
            if r < l {
                multiSwap(m - r, m, r)
                b -= r
                m -= r
                l -= r
            } else {
                multiSwap(a, m, l)
                a += l
                m += l
                r -= l
            }
        }
    }

    /// Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
    /// assuming [a, b) is already sorted by that digit.
    func digitLowerBound(_ a: Int, _ b: Int, _ d: Int, _ place: Int) -> Int {
        var a = a
        var b = b
        while a < b {
            let mid = (a + b) / 2
            if digitAt(arr[mid], place) >= d {
                b = mid
            } else {
                a = mid + 1
            }
        }
        return a
    }

    /// Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-
    /// `place` values are known to lie in [da, db), by rotating the below-threshold
    /// prefixes of both runs together and recursing into the two halves that
    /// produces.
    func mergeByDigit(_ a: Int, _ m: Int, _ b: Int, _ da: Int, _ db: Int, _ place: Int) {
        guard b - a >= 2, db - da >= 2 else { return }
        let dm = (da + db) / 2
        let m1 = digitLowerBound(a, m, dm, place)
        let m2 = digitLowerBound(m, b, dm, place)
        rotateBlock(m1, m, m2)
        let newM = m1 + (m2 - m)
        mergeByDigit(newM, m2, b, dm, db, place)
        mergeByDigit(a, m1, newM, da, dm, place)
    }

    /// Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
    /// index range, merging with mergeByDigit instead of a linear merge.
    func digitMergeSort(_ a: Int, _ b: Int, _ place: Int) {
        guard b - a >= 2 else { return }
        let mid = (a + b) / 2
        digitMergeSort(a, mid, place)
        digitMergeSort(mid, b, place)
        mergeByDigit(a, mid, b, 0, radixBase, place)
    }

    let maxValue = arr.max() ?? 0
    var maxPlace = 0
    var probe = radixBase
    while probe <= maxValue {
        maxPlace += 1
        probe *= radixBase
    }
    for place in 0 ... maxPlace {
        digitMergeSort(0, n, place)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
