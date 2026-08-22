import Foundation

func slowSort(_ array: inout [Int], _ i: Int, _ j: Int) {
    if i >= j {
        return
    }
    let m = i + (j - i) / 2
    slowSort(&array, i, m)
    slowSort(&array, m + 1, j)
    if array[m] > array[j] {
        array.swapAt(m, j)
    }
    slowSort(&array, i, j - 1)
}

func sort(_ array: inout [Int]) {
    slowSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
