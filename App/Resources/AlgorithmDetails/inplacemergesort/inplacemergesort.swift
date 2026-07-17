import Foundation

func push(_ array: inout [Int], _ low: Int, _ high: Int) {
    var i = low
    while i < high {
        if array[i] > array[i + 1] {
            array.swapAt(i, i + 1)
        }
        i += 1
    }
}

func merge(_ array: inout [Int], _ low: Int, _ high: Int, _ mid: Int) {
    var i = low
    while i <= mid {
        if array[i] > array[mid + 1] {
            array.swapAt(i, mid + 1)
            push(&array, mid + 1, high)
        }
        i += 1
    }
}

func mergeSort(_ array: inout [Int], _ low: Int, _ high: Int) {
    if high - low == 0 {
        return
    } else if high - low == 1 {
        if array[low] > array[high] {
            array.swapAt(low, high)
        }
    } else {
        let mid = (low + high) / 2
        mergeSort(&array, low, mid)
        mergeSort(&array, mid + 1, high)
        merge(&array, low, high, mid)
    }
}

func sort(_ array: inout [Int]) {
    guard array.count >= 2 else {
        return
    }
    mergeSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
