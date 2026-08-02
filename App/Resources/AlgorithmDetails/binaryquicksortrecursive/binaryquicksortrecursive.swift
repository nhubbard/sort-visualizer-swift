func mostSignificantBit(_ value: Int) -> Int {
    if value == 0 { return -1 }
    var bit = 0
    while (value >> (bit + 1)) != 0 { bit += 1 }
    return bit
}

func partition(_ arr: inout [Int], _ p: Int, _ r: Int, _ bit: Int) -> Int {
    var i = p - 1
    var j = r + 1
    while true {
        i += 1
        while i <= r && ((arr[i] >> bit) & 1) == 0 { i += 1 }
        j -= 1
        while j >= p && ((arr[j] >> bit) & 1) == 1 { j -= 1 }
        if i < j {
            arr.swapAt(i, j)
        } else {
            return j
        }
    }
}

func binaryQuickSortRecursive(_ arr: inout [Int], _ p: Int, _ r: Int, _ bit: Int) {
    if p < r && bit >= 0 {
        let q = partition(&arr, p, r, bit)
        binaryQuickSortRecursive(&arr, p, q, bit - 1)
        binaryQuickSortRecursive(&arr, q + 1, r, bit - 1)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    let maxValue = arr.max() ?? 0
    let bit = mostSignificantBit(maxValue)
    binaryQuickSortRecursive(&arr, 0, n - 1, bit)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
