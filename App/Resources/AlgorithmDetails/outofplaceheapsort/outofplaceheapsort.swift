func siftDown(_ arr: inout [Int], _ root: Int, _ size: Int) {
    var index = root
    while 2 * index + 1 < size {
        var child = 2 * index + 1
        if child + 1 < size, arr[child + 1] > arr[child] {
            child += 1
        }
        index = child
    }
    let rootValue = arr[root]
    while rootValue > arr[index] {
        index = (index - 1) / 2
    }
    while index != root {
        arr.swapAt(root, index)
        index = (index - 1) / 2
    }
}

func heapify(_ arr: inout [Int], _ length: Int) {
    var i = (length - 1) / 2
    while i >= 0 {
        siftDown(&arr, i, length)
        i -= 1
    }
}

func findNext(_ arr: inout [Int], _ size: Int) {
    var hole = 0
    var left = 1
    var right = 2
    while right < size, !(arr[left] == -1 && arr[right] == -1) {
        if arr[left] == -1 {
            arr.swapAt(hole, right)
            hole = right
        } else if arr[right] == -1 {
            arr.swapAt(hole, left)
            hole = left
        } else if arr[right] > arr[left] {
            arr.swapAt(hole, right)
            hole = right
        } else {
            arr.swapAt(hole, left)
            hole = left
        }
        left = 2 * hole + 1
        right = left + 1
    }
    if left < size, arr[left] != -1 {
        arr.swapAt(hole, left)
    }
}

func sort(_ arr: inout [Int]) -> [Int] {
    let n = arr.count
    var output = [Int](repeating: 0, count: n)
    guard n > 1 else {
        if n == 1 {
            output[0] = arr[0]
        }
        return output
    }
    heapify(&arr, n)
    var i = n - 1
    while i >= 0 {
        output[i] = arr[0]
        arr[0] = -1
        findNext(&arr, n)
        i -= 1
    }
    return output
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
let output = sort(&array)
print(output)
