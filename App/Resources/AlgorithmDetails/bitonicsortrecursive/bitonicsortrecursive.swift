import Foundation

func greatestPowerOfTwoLessThan(_ n: Int) -> Int {
    var k = 1
    while k < n {
        k <<= 1
    }
    return k >> 1
}

func compare(_ array: inout [Int], _ i: Int, _ j: Int, _ dir: Bool) {
    let isGreater = array[i] > array[j]
    if dir == isGreater {
        array.swapAt(i, j)
    }
}

func bitonicMerge(_ array: inout [Int], _ lo: Int, _ n: Int, _ dir: Bool) {
    if n > 1 {
        let m = greatestPowerOfTwoLessThan(n)
        for i in lo ..< (lo + n - m) {
            compare(&array, i, i + m, dir)
        }
        bitonicMerge(&array, lo, m, dir)
        bitonicMerge(&array, lo + m, n - m, dir)
    }
}

func bitonicSort(_ array: inout [Int], _ lo: Int, _ n: Int, _ dir: Bool) {
    if n > 1 {
        let m = n / 2
        bitonicSort(&array, lo, m, !dir)
        bitonicSort(&array, lo + m, n - m, dir)
        bitonicMerge(&array, lo, n, dir)
    }
}

func sort(_ array: inout [Int]) {
    bitonicSort(&array, 0, array.count, true)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
