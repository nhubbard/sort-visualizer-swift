let base = 4

func siftDown(_ arr: inout [Int], _ node: Int, _ stop: Int) {
    let left = node * base + 1
    if left >= stop {
        return
    }
    var maxIndex = left
    var i = left + 1
    while i < left + base && i < stop {
        if arr[maxIndex] < arr[i] {
            maxIndex = i
        }
        i += 1
    }
    if arr[node] < arr[maxIndex] {
        arr.swapAt(node, maxIndex)
        siftDown(&arr, maxIndex, stop)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var i = n - 1
    while i >= 0 {
        siftDown(&arr, i, n)
        i -= 1
    }
    var end = n - 1
    while end > 0 {
        arr.swapAt(0, end)
        siftDown(&arr, 0, end)
        end -= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
