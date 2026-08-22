import Foundation

func intPow(_ base: Int, _ exponent: Int) -> Int {
    var result = 1
    for _ in 0 ..< exponent {
        result *= base
    }
    return result
}

func getDigit(_ value: Int, _ place: Int, _ base: Int) -> Int {
    (value / intPow(base, place)) % base
}

func multiSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ length: Int) {
    for i in 0 ..< length {
        arr.swapAt(a + i, b + i)
    }
}

func rotate(_ arr: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    var a = a
    var m = m
    var b = b
    var l = m - a
    var r = b - m
    while l > 0, r > 0 {
        if r < l {
            multiSwap(&arr, m - r, m, r)
            b -= r
            m -= r
            l -= r
        } else {
            multiSwap(&arr, a, m, l)
            a += l
            m += l
            r -= l
        }
    }
}

func binSearchDigit(_ arr: [Int], _ a: Int, _ b: Int, _ d: Int, _ place: Int, _ base: Int) -> Int {
    var a = a
    var b = b
    while a < b {
        let mid = (a + b) / 2
        if getDigit(arr[mid], place, base) >= d {
            b = mid
        } else {
            a = mid + 1
        }
    }
    return a
}

func mergeDigit(
    _ arr: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ da: Int, _ db: Int, _ place: Int,
    _ base: Int
) {
    if b - a < 2 || db - da < 2 {
        return
    }
    let dm = (da + db) / 2
    let m1 = binSearchDigit(arr, a, m, dm, place, base)
    let m2 = binSearchDigit(arr, m, b, dm, place, base)
    rotate(&arr, m1, m, m2)
    let newM = m1 + (m2 - m)
    mergeDigit(&arr, newM, m2, b, dm, db, place, base)
    mergeDigit(&arr, a, m1, newM, da, dm, place, base)
}

func mergeSortDigit(_ arr: inout [Int], _ a: Int, _ b: Int, _ place: Int, _ base: Int) {
    if b - a < 2 {
        return
    }
    let mid = (a + b) / 2
    mergeSortDigit(&arr, a, mid, place, base)
    mergeSortDigit(&arr, mid, b, place, base)
    mergeDigit(&arr, a, mid, b, 0, base, place, base)
}

/// Digit-sorts [a, b) in place by `place` using rotation instead of counting
/// buckets, then recurses into every resulting digit bucket one place lower --
/// an ordinary MSD radix sort built entirely out of the LSD variant's
/// rotate/binary-search machinery.
func msdRotateSort(_ arr: inout [Int], _ a: Int, _ b: Int, _ place: Int, _ base: Int) {
    if b - a < 2 || place < 0 {
        return
    }
    mergeSortDigit(&arr, a, b, place, base)
    var start = a
    for d in 0 ..< base {
        let end = binSearchDigit(arr, start, b, d + 1, place, base)
        msdRotateSort(&arr, start, end, place - 1, base)
        start = end
    }
}

func sort(_ arr: inout [Int]) {
    if arr.count <= 1 {
        return
    }
    let base = 4
    let maxValue = arr.max() ?? 0
    var highestPlace = 0
    var probe = base
    while probe <= maxValue {
        highestPlace += 1
        probe *= base
    }
    msdRotateSort(&arr, 0, arr.count, highestPlace, base)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
