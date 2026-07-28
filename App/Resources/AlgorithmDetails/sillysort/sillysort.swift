func sillySort(_ arr: inout [Int], _ i: Int, _ j: Int) {
    if i < j {
        let m = i + (j - i) / 2
        sillySort(&arr, i, m)
        sillySort(&arr, m + 1, j)
        if arr[i] >= arr[m + 1] {
            arr.swapAt(i, m + 1)
        }
        sillySort(&arr, i + 1, j)
    }
}

func sort(_ array: inout [Int]) {
    sillySort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
