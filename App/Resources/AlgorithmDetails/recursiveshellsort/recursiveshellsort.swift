import Foundation

func sort(_ array: inout [Int]) {
    recursiveShellSort(&array, 0, array.count, 1)
}

func gappedInsertionSort(_ array: inout [Int], _ a: Int, _ b: Int, _ gap: Int) {
    var i = a + gap
    while i < b {
        var j = i
        while j - gap >= a && array[j] < array[j - gap] {
            array.swapAt(j, j - gap)
            j -= gap
        }
        i += gap
    }
}

func recursiveShellSort(_ array: inout [Int], _ start: Int, _ end: Int, _ g: Int) {
    if start + g <= end {
        recursiveShellSort(&array, start, end, 3 * g)
        recursiveShellSort(&array, start + g, end, 3 * g)
        recursiveShellSort(&array, start + 2 * g, end, 3 * g)
        gappedInsertionSort(&array, start, end, g)
    }
}


var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
