func stablePartition(_ arr: inout [Int], _ start: Int, _ end: Int) -> Int {
    let pivotValue = arr[start]
    var leftList: [Int] = []
    var rightList: [Int] = []

    for i in (start + 1) ... end {
        if arr[i] < pivotValue {
            leftList.append(arr[i])
        } else {
            rightList.append(arr[i])
        }
    }

    var writeIndex = start
    for v in leftList {
        arr[writeIndex] = v
        writeIndex += 1
    }
    let pivotIndex = writeIndex
    arr[writeIndex] = pivotValue
    writeIndex += 1
    for v in rightList {
        arr[writeIndex] = v
        writeIndex += 1
    }
    return pivotIndex
}

func stableQuickSort(_ arr: inout [Int], _ start: Int, _ end: Int) {
    if start < end {
        let p = stablePartition(&arr, start, end)
        stableQuickSort(&arr, start, p - 1)
        stableQuickSort(&arr, p + 1, end)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    stableQuickSort(&arr, 0, n - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
