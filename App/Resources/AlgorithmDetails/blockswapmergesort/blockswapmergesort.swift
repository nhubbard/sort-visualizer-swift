import Foundation

func multiSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ len: Int) {
    for i in 0 ..< len {
        array.swapAt(a + i, b + i)
    }
}

func binarySearchMid(_ array: [Int], _ start: Int, _ mid: Int, _ end: Int) -> Int {
    var a = 0
    var b = min(mid - start, end - mid)
    var m = a + (b - a) / 2
    while b > a {
        if array[mid - m - 1] > array[mid + m] {
            a = m + 1
        } else {
            b = m
        }
        m = a + (b - a) / 2
    }
    return m
}

func multiSwapMerge(_ array: inout [Int], _ start: Int, _ midIn: Int, _ endIn: Int) {
    var mid = midIn
    var end = endIn
    var m = binarySearchMid(array, start, mid, end)
    while m > 0 {
        multiSwap(&array, mid - m, mid, m)
        multiSwapMerge(&array, mid, mid + m, end)
        end = mid
        mid -= m
        m = binarySearchMid(array, start, mid, end)
    }
}

func multiSwapMergeSort(_ array: inout [Int], _ a: Int, _ b: Int) {
    let len = b - a
    var i = a
    var j = 1
    while j < len {
        i = a
        while i + 2 * j <= b {
            multiSwapMerge(&array, i, i + j, i + 2 * j)
            i += 2 * j
        }
        if i + j < b {
            multiSwapMerge(&array, i, i + j, b)
        }
        j *= 2
    }
}

func sort(_ array: inout [Int]) {
    multiSwapMergeSort(&array, 0, array.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
