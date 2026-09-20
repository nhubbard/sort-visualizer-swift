import Foundation

func partition(_ array: inout [Int], _ begin: Int, _ end: Int) -> Int {
    var i = begin
    var j = end
    while i < j {
        while i < j && array[i] <= array[begin] { i += 1 }
        while array[j] > array[begin] { j -= 1 }
        if i < j { array.swapAt(i, j) }
    }
    array.swapAt(begin, j)
    return j
}

func quickSort(_ array: inout [Int], _ begin: Int, _ end: Int) {
    if begin < end {
        let partitionIndex = partition(&array, begin, end)
        quickSort(&array, begin, partitionIndex - 1)
        quickSort(&array, partitionIndex + 1, end)
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
