import Foundation

func compSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
    if b < end, array[a] > array[b] {
        array.swapAt(a, b)
    }
}

func pairwiseMerge(_ array: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
    let m = (a + b) / 2
    let m1 = (a + m) / 2
    let g = m - m1

    for i in 0 ..< (m - m1) {
        var j = m1
        var k = g
        while k > 0 {
            compSwap(&array, j + i, j + i + k, end)
            k >>= 1
            j -= (k - (i & k))
        }
    }
    if b - a > 4 {
        pairwiseMerge(&array, m, b, end)
    }
}

func pairwiseMergeSort(_ array: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
    let m = (a + b) / 2
    var i = a
    var j = m
    while i < m {
        compSwap(&array, i, j, end)
        i += 1
        j += 1
    }
    if b - a > 2 {
        pairwiseMergeSort(&array, a, m, end)
        pairwiseMergeSort(&array, m, b, end)
        pairwiseMerge(&array, a, b, end)
    }
}

func sort(_ arr: inout [Int]) {
    let length = arr.count
    let end = length

    var n = 1
    while n < length {
        n <<= 1
    }

    pairwiseMergeSort(&arr, 0, n, end)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
