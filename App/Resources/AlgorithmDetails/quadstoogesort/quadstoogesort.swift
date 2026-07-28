func quadStooge(_ arr: inout [Int], _ pos: Int, _ length: Int) {
    if length >= 2 && arr[pos] > arr[pos + length - 1] {
        arr.swapAt(pos, pos + length - 1)
    }
    if length <= 2 {
        return
    }

    let len1 = length / 2
    let len2 = (length + 1) / 2
    let len3 = (len1 + 1) / 2 + (len2 + 1) / 2

    quadStooge(&arr, pos, len1)
    quadStooge(&arr, pos + len1, len2)
    quadStooge(&arr, pos + len1 / 2, len3)
    quadStooge(&arr, pos + len1, len2)
    quadStooge(&arr, pos, len1)
    if length > 3 {
        quadStooge(&arr, pos + len1 / 2, len3)
    }
}

func sort(_ array: inout [Int]) {
    quadStooge(&array, 0, array.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
