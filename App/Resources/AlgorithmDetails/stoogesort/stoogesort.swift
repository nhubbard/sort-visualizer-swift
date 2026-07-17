func stoogeSort(_ arr: inout [Int],
_ i: Int,
_ j: Int) {
    if arr[i] > arr[j] {
        arr.swapAt(i, j)
    }
    if j - i > 1 {
        let t = (j - i + 1) / 3
        stoogeSort(&arr, i, j - t)
        stoogeSort(&arr, i + t, j)
        stoogeSort(&arr, i, j - t)
    }
}

func sort(_ array: inout [Int]) {
    stoogeSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
