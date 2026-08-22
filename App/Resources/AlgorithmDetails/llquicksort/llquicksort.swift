import Foundation

func partition(_ array: inout [Int],
               _ lo: Int,
               _ hi: Int) -> Int
{
    let pivot = array[hi]
    var i = lo
    for j in lo ..< hi where array[j] < pivot {
        array.swapAt(i, j)
        i += 1
    }
    array.swapAt(i, hi)
    return i
}

func quickSort(_ array: inout [Int], _ lo: Int, _ hi: Int) {
    if lo < hi {
        let p = partition(&array, lo, hi)
        quickSort(&array, lo, p - 1)
        quickSort(&array, p + 1, hi)
    }
}

func sort(_ array: inout [Int]) {
    quickSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
