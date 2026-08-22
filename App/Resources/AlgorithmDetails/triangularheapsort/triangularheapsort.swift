import Foundation

func triangularRoot(_ val: Int) -> Int {
    let integerSqrt = Int(Double(8 * val + 1).squareRoot())
    return (integerSqrt - 1) / 2
}

func siftDown(_ array: inout [Int], _ rootIn: Int, _ size: Int) {
    var root = rootIn
    while true {
        let row = triangularRoot(root)
        let left = root + row + 1
        if left >= size {
            break
        }
        let right = left + 1
        var largest = root
        if array[largest] < array[left] {
            largest = left
        }
        if right < size, array[largest] < array[right] {
            largest = right
        }
        if largest == root {
            break
        }
        array.swapAt(root, largest)
        root = largest
    }
}

func heapify(_ array: inout [Int], _ length: Int) {
    var i = length - 1
    while i >= 0 {
        siftDown(&array, i, length)
        i -= 1
    }
}

func sort(_ array: inout [Int]) {
    let n = array.count
    guard n > 1 else {
        return
    }
    heapify(&array, n)
    var i = 1
    while i < n - 1 {
        array.swapAt(0, n - i)
        siftDown(&array, 0, n - i)
        i += 1
    }
    if array[0] > array[1] {
        array.swapAt(0, 1)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
