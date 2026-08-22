import Foundation

func hyperfloor(_ n: Int) -> Int {
    var power = 1
    while power * 2 <= n {
        power *= 2
    }
    return power
}

func uncheckedInsertionSort(_ array: inout [Int], _ first: Int, _ last: Int) {
    var cur = first + 1
    while cur != last {
        if array[cur] < array[cur - 1] {
            let tmp = array[cur]
            var sift = cur
            var sift1 = cur - 1
            while true {
                array[sift] = array[sift1]
                sift -= 1
                if sift == first {
                    break
                }
                sift1 -= 1
                if tmp >= array[sift1] {
                    break
                }
            }
            array[sift] = tmp
        }
        cur += 1
    }
}

func insertionSort(_ array: inout [Int], _ first: Int, _ last: Int) {
    if first == last {
        return
    }
    uncheckedInsertionSort(&array, first, last)
}

func poplarSift(_ array: inout [Int], _ firstIn: Int, _ sizeIn: Int) {
    var size = sizeIn
    guard size >= 2 else {
        return
    }
    var root = firstIn + (size - 1)
    var childRoot1 = root - 1
    var childRoot2 = firstIn + (size / 2 - 1)
    while true {
        var maxRoot = root
        if array[maxRoot] < array[childRoot1] {
            maxRoot = childRoot1
        }
        if array[maxRoot] < array[childRoot2] {
            maxRoot = childRoot2
        }
        if maxRoot == root {
            return
        }
        array.swapAt(root, maxRoot)
        size /= 2
        if size < 2 {
            return
        }
        root = maxRoot
        childRoot1 = root - 1
        childRoot2 = maxRoot - (size - size / 2)
    }
}

func popHeapWithSize(_ array: inout [Int], _ first: Int, _ last: Int, _ sizeIn: Int) {
    var size = sizeIn
    var poplarSize = hyperfloor(size + 1) - 1
    let lastRoot = last - 1
    var bigger = lastRoot
    var biggerSize = poplarSize

    var it = first
    while true {
        let root = it + poplarSize - 1
        if root == lastRoot {
            break
        }
        if array[bigger] < array[root] {
            bigger = root
            biggerSize = poplarSize
        }
        it = root + 1
        size -= poplarSize
        poplarSize = hyperfloor(size + 1) - 1
    }

    if bigger != lastRoot {
        array.swapAt(bigger, lastRoot)
        poplarSift(&array, bigger - (biggerSize - 1), biggerSize)
    }
}

func makeHeap(_ array: inout [Int], _ first: Int, _ last: Int) {
    let size = last - first
    guard size >= 2 else {
        return
    }
    let smallPoplarSize = 15
    if size <= smallPoplarSize {
        uncheckedInsertionSort(&array, first, last)
        return
    }

    var poplarLevel = 1
    var it = first
    var next = it + smallPoplarSize
    while true {
        uncheckedInsertionSort(&array, it, next)
        var poplarSize = smallPoplarSize
        var i = (poplarLevel & -poplarLevel) >> 1
        while i != 0 {
            it -= poplarSize
            poplarSize = 2 * poplarSize + 1
            if it + poplarSize > last {
                break
            }
            poplarSift(&array, it, poplarSize)
            next += 1
            i >>= 1
        }
        if (last - next) <= smallPoplarSize {
            insertionSort(&array, next, last)
            return
        }
        it = next
        next += smallPoplarSize
        poplarLevel += 1
    }
}

func sortHeap(_ array: inout [Int], _ first: Int, _ lastIn: Int) {
    var last = lastIn
    var size = last - first
    guard size >= 2 else {
        return
    }
    repeat {
        popHeapWithSize(&array, first, last, size)
        last -= 1
        size -= 1
    } while size > 1
}

func sort(_ array: inout [Int]) {
    let n = array.count
    guard n > 1 else {
        return
    }
    makeHeap(&array, 0, n)
    sortHeap(&array, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
