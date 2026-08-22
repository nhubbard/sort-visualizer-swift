import Foundation

func findMinMax(_ array: [Int], _ a: Int, _ b: Int) -> (min: Int, max: Int) {
    var minValue = array[a]
    var maxValue = minValue
    var i = a + 1
    while i < b {
        if array[i] < minValue {
            minValue = array[i]
        } else if array[i] > maxValue {
            maxValue = array[i]
        }
        i += 1
    }
    return (minValue, maxValue)
}

func insertionSortRange(_ array: inout [Int], _ s: Int, _ e: Int) {
    guard e - s > 1 else {
        return
    }
    for i in (s + 1) ..< e {
        var j = i
        while j > s, array[j - 1] > array[j] {
            array.swapAt(j - 1, j)
            j -= 1
        }
    }
}

func siftDown(_ array: inout [Int], _ s: Int, _ root: Int, _ size: Int) {
    var root = root
    while true {
        var largest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size, array[s + largest] < array[s + left] {
            largest = left
        }
        if right < size, array[s + largest] < array[s + right] {
            largest = right
        }
        if largest == root {
            break
        }
        array.swapAt(s + root, s + largest)
        root = largest
    }
}

func heapSortRange(_ array: inout [Int], _ s: Int, _ e: Int) {
    let size = e - s
    guard size > 1 else {
        return
    }
    var i = size / 2 - 1
    while i >= 0 {
        siftDown(&array, s, i, size)
        i -= 1
    }
    var end = size - 1
    while end > 0 {
        array.swapAt(s, s + end)
        siftDown(&array, s, 0, end)
        end -= 1
    }
}

func staticSort(_ array: inout [Int], _ a: Int, _ b: Int) {
    let (minValue, maxValue) = findMinMax(array, a, b)
    let auxLen = b - a
    var count = [Int](repeating: 0, count: auxLen + 1)
    var offset = [Int](repeating: 0, count: auxLen + 1)
    let CONST = Double(auxLen) / Double(maxValue - minValue + 1)

    func classify(_ value: Int) -> Int {
        Int(Double(value - minValue) * CONST)
    }

    for i in a ..< b {
        let idx = classify(array[i])
        count[idx] += 1
    }

    offset[0] = a
    for i in 1 ..< auxLen {
        offset[i] = count[i - 1] + offset[i - 1]
    }

    for v in 0 ..< auxLen {
        while count[v] > 0 {
            let origin = offset[v]
            var from = origin
            var num = array[from]
            array[from] = -1
            repeat {
                let idx = classify(num)
                let to = offset[idx]
                offset[idx] += 1
                count[idx] -= 1
                let temp = array[to]
                array[to] = num
                num = temp
                from = to
            } while from != origin
        }
    }

    for i in 0 ..< auxLen {
        let s = (i > 1) ? offset[i - 1] : a
        let e = offset[i]
        if e - s <= 1 {
            continue
        }
        if e - s > 16 {
            heapSortRange(&array, s, e)
        } else {
            insertionSortRange(&array, s, e)
        }
    }
}

func sort(_ array: inout [Int]) {
    if array.count > 1 {
        staticSort(&array, 0, array.count)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
