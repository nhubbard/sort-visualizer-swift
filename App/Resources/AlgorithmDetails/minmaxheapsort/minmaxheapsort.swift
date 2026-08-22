import Foundation

func bitLength(_ valueIn: Int) -> Int {
    var value = valueIn
    var length = 0
    while value > 0 {
        value >>= 1
        length += 1
    }
    return length
}

func isMinLevel(_ index: Int) -> Bool {
    bitLength(index + 1) % 2 == 1
}

func betterThan(_ a: Int, _ b: Int, _ minLevel: Bool) -> Bool {
    minLevel ? a < b : a > b
}

func downheap(_ arr: inout [Int], _ start: Int, _ size: Int) {
    var i = start
    while true {
        let minLevel = isMinLevel(i)
        let left = 2 * i + 1
        let right = 2 * i + 2
        if left >= size {
            return
        }
        var winner = left
        if right < size, betterThan(arr[right], arr[winner], minLevel) {
            winner = right
        }
        let base = 4 * i + 3
        for offset in 0 ..< 4 {
            let gc = base + offset
            if gc < size, betterThan(arr[gc], arr[winner], minLevel) {
                winner = gc
            }
        }
        let isGrandchild = winner >= base
        let extreme = betterThan(arr[winner], arr[i], minLevel)
        if !isGrandchild {
            if extreme {
                arr.swapAt(i, winner)
            }
            return
        }
        if extreme {
            arr.swapAt(i, winner)
        } else {
            return
        }
        let parent = (winner - 1) / 2
        if minLevel {
            if arr[winner] > arr[parent] {
                arr.swapAt(parent, winner)
            }
        } else {
            if arr[winner] < arr[parent] {
                arr.swapAt(parent, winner)
            }
        }
        i = winner
    }
}

func heapify(_ arr: inout [Int], _ length: Int) {
    var i = (length - 1) / 2
    while i >= 0 {
        downheap(&arr, i, length)
        i -= 1
    }
}

func storeMax(_ arr: inout [Int], _ heapSize: Int) -> Int {
    if heapSize <= 1 {
        return heapSize
    }
    var imax = 1
    if heapSize > 2, arr[2] > arr[1] {
        imax = 2
    }
    let last = heapSize - 1
    arr.swapAt(imax, last)
    let newSize = last
    if imax < newSize {
        downheap(&arr, imax, newSize)
    }
    return newSize
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else {
        return
    }
    heapify(&arr, n)
    var heapSize = n
    var i = 0
    while i < n - 1 {
        heapSize = storeMax(&arr, heapSize)
        i += 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
