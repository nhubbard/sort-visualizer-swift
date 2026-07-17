import Foundation

func multiSwap(_ arr: inout [Int], _ pos: Int, _ to: Int) {
    if to - pos > 0 {
        var i = pos
        while i < to {
            arr.swapAt(i, i + 1)
            i += 1
        }
    } else {
        var i = pos
        while i > to {
            arr.swapAt(i, i - 1)
            i -= 1
        }
    }
}

func weaveInsert(_ arr: inout [Int], _ start: Int, _ end: Int) {
    for j in start ..< end {
        var pos = j
        while pos > start && arr[pos] <= arr[pos - 1] {
            arr.swapAt(pos, pos - 1)
            pos -= 1
        }
    }
}

func weaveMerge(_ arr: inout [Int], _ min: Int, _ max: Int, _ mid: Int) {
    let target = mid - min
    var i = 1
    while i <= target {
        multiSwap(&arr, mid + i, min + (i * 2) - 1)
        i += 1
    }
    weaveInsert(&arr, min, max + 1)
}

func weaveMergeSort(_ arr: inout [Int], _ min: Int, _ max: Int) {
    if max - min == 0 {
        return
    } else if max - min == 1 {
        if arr[min] > arr[max] {
            arr.swapAt(min, max)
        }
    } else {
        let mid = (min + max) / 2
        weaveMergeSort(&arr, min, mid)
        weaveMergeSort(&arr, mid + 1, max)
        weaveMerge(&arr, min, max, mid)
    }
}

func sort(_ arr: inout [Int]) {
    if arr.count > 1 {
        weaveMergeSort(&arr, 0, arr.count - 1)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
