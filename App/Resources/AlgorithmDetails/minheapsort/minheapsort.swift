import Foundation

func siftDown(_ arr: inout [Int], _ root: Int, _ size: Int) {
    var root = root
    while true {
        var smallest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size && arr[left] < arr[smallest] {
            smallest = left
        }
        if right < size && arr[right] < arr[smallest] {
            smallest = right
        }
        if smallest == root {
            break
        }
        arr.swapAt(root, smallest)
        root = smallest
    }
}

func heapify(_ arr: inout [Int]) {
    var i = arr.count / 2 - 1
    while i >= 0 {
        siftDown(&arr, i, arr.count)
        i -= 1
    }
}

func sort(_ arr: inout [Int]) {
    heapify(&arr)
    var end = arr.count - 1
    while end > 0 {
        arr.swapAt(0, end)
        siftDown(&arr, 0, end)
        end -= 1
    }
    arr.reverse()
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
