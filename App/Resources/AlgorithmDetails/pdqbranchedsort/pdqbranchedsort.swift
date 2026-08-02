let insertSortThreshold = 24
let nintherThreshold = 128
let partialInsertSortLimit = 8

func pdqLog(_ n0: Int) -> Int {
    var n = n0
    var log = 0
    while true {
        n >>= 1
        if n == 0 {
            break
        }
        log += 1
    }
    return log
}

func insertSort(_ arr: inout [Int], _ begin: Int, _ end: Int) {
    for cur in (begin + 1) ..< end {
        if arr[cur] < arr[cur - 1] {
            let tmp = arr[cur]
            var sift = cur
            var siftMinusOne = cur - 1
            repeat {
                arr[sift] = arr[siftMinusOne]
                sift -= 1
                siftMinusOne -= 1
            } while sift != begin && tmp < arr[siftMinusOne]
            arr[sift] = tmp
        }
    }
}

func unguardInsertSort(_ arr: inout [Int], _ begin: Int, _ end: Int) {
    for cur in (begin + 1) ..< end {
        if arr[cur] < arr[cur - 1] {
            let tmp = arr[cur]
            var sift = cur
            var siftMinusOne = cur - 1
            repeat {
                arr[sift] = arr[siftMinusOne]
                sift -= 1
                siftMinusOne -= 1
            } while tmp < arr[siftMinusOne]
            arr[sift] = tmp
        }
    }
}

func partialInsertSort(_ arr: inout [Int], _ begin: Int, _ end: Int) -> Bool {
    var limit = 0
    for cur in (begin + 1) ..< end {
        if limit > partialInsertSortLimit {
            return false
        }
        if arr[cur] < arr[cur - 1] {
            let tmp = arr[cur]
            var sift = cur
            var siftMinusOne = cur - 1
            repeat {
                arr[sift] = arr[siftMinusOne]
                sift -= 1
                siftMinusOne -= 1
            } while sift != begin && tmp < arr[siftMinusOne]
            arr[sift] = tmp
            limit += cur - sift
        }
    }
    return true
}

func sortTwo(_ arr: inout [Int], _ a: Int, _ b: Int) {
    if arr[b] < arr[a] {
        arr.swapAt(a, b)
    }
}

func sortThree(_ arr: inout [Int], _ a: Int, _ b: Int, _ c: Int) {
    sortTwo(&arr, a, b)
    sortTwo(&arr, b, c)
    sortTwo(&arr, a, b)
}

func partRight(_ arr: inout [Int], _ begin: Int, _ end: Int) -> (Int, Bool) {
    let pivot = arr[begin]
    var first = begin
    var last = end

    first += 1
    while arr[first] < pivot {
        first += 1
    }

    if first - 1 == begin {
        last -= 1
        while first < last, !(arr[last] < pivot) {
            last -= 1
        }
    } else {
        last -= 1
        while !(arr[last] < pivot) {
            last -= 1
        }
    }

    let alreadyParted = first >= last
    while first < last {
        arr.swapAt(first, last)
        first += 1
        while arr[first] < pivot {
            first += 1
        }
        last -= 1
        while !(arr[last] < pivot) {
            last -= 1
        }
    }

    let pivotPos = first - 1
    arr[begin] = arr[pivotPos]
    arr[pivotPos] = pivot

    return (pivotPos, alreadyParted)
}

func partLeft(_ arr: inout [Int], _ begin: Int, _ end: Int) -> Int {
    let pivot = arr[begin]
    var first = begin
    var last = end

    last -= 1
    while pivot < arr[last] {
        last -= 1
    }

    if last + 1 == end {
        first += 1
        while first < last && !(pivot < arr[first]) {
            first += 1
        }
    } else {
        first += 1
        while !(pivot < arr[first]) {
            first += 1
        }
    }

    while first < last {
        arr.swapAt(first, last)
        last -= 1
        while pivot < arr[last] {
            last -= 1
        }
        first += 1
        while !(pivot < arr[first]) {
            first += 1
        }
    }

    let pivotPos = last
    arr[begin] = arr[pivotPos]
    arr[pivotPos] = pivot
    return pivotPos
}

func siftDown(_ arr: inout [Int], _ begin: Int, _ root0: Int, _ size: Int) {
    var root = root0
    while true {
        var child = 2 * root + 1
        if child >= size {
            break
        }
        if child + 1 < size, arr[begin + child] < arr[begin + child + 1] {
            child += 1
        }
        if arr[begin + root] < arr[begin + child] {
            arr.swapAt(begin + root, begin + child)
            root = child
        } else {
            break
        }
    }
}

func heapSort(_ arr: inout [Int], _ begin: Int, _ end: Int) {
    let n = end - begin
    if n / 2 - 1 >= 0 {
        for i in stride(from: n / 2 - 1, through: 0, by: -1) {
            siftDown(&arr, begin, i, n)
        }
    }
    if n - 1 >= 1 {
        for i in stride(from: n - 1, through: 1, by: -1) {
            arr.swapAt(begin, begin + i)
            siftDown(&arr, begin, 0, i)
        }
    }
}

func pdqLoop(_ arr: inout [Int], _ begin0: Int, _ end: Int, _ badAllowed0: Int) {
    var begin = begin0
    var badAllowed = badAllowed0
    var leftmost = true
    while true {
        let size = end - begin

        if size < insertSortThreshold {
            if leftmost {
                insertSort(&arr, begin, end)
            } else {
                unguardInsertSort(&arr, begin, end)
            }
            return
        }

        let halfSize = size / 2
        if size > nintherThreshold {
            sortThree(&arr, begin, begin + halfSize, end - 1)
            sortThree(&arr, begin + 1, begin + halfSize - 1, end - 2)
            sortThree(&arr, begin + 2, begin + halfSize + 1, end - 3)
            sortThree(&arr, begin + halfSize - 1, begin + halfSize, begin + halfSize + 1)
            arr.swapAt(begin, begin + halfSize)
        } else {
            sortThree(&arr, begin + halfSize, begin, end - 1)
        }

        if !leftmost && !(arr[begin - 1] < arr[begin]) {
            begin = partLeft(&arr, begin, end) + 1
            continue
        }

        let (pivotPos, alreadyParted) = partRight(&arr, begin, end)

        let leftSize = pivotPos - begin
        let rightSize = end - (pivotPos + 1)
        let highUnbalance = leftSize < size / 8 || rightSize < size / 8

        if highUnbalance {
            badAllowed -= 1
            if badAllowed == 0 {
                heapSort(&arr, begin, end)
                return
            }

            if leftSize >= insertSortThreshold {
                arr.swapAt(begin, begin + leftSize / 4)
                arr.swapAt(pivotPos - 1, pivotPos - leftSize / 4)
                if leftSize > nintherThreshold {
                    arr.swapAt(begin + 1, begin + (leftSize / 4 + 1))
                    arr.swapAt(begin + 2, begin + (leftSize / 4 + 2))
                    arr.swapAt(pivotPos - 2, pivotPos - (leftSize / 4 + 1))
                    arr.swapAt(pivotPos - 3, pivotPos - (leftSize / 4 + 2))
                }
            }

            if rightSize >= insertSortThreshold {
                arr.swapAt(pivotPos + 1, pivotPos + (1 + rightSize / 4))
                arr.swapAt(end - 1, end - rightSize / 4)
                if rightSize > nintherThreshold {
                    arr.swapAt(pivotPos + 2, pivotPos + (2 + rightSize / 4))
                    arr.swapAt(pivotPos + 3, pivotPos + (3 + rightSize / 4))
                    arr.swapAt(end - 2, end - (1 + rightSize / 4))
                    arr.swapAt(end - 3, end - (2 + rightSize / 4))
                }
            }
        } else {
            if alreadyParted, partialInsertSort(&arr, begin, pivotPos), partialInsertSort(&arr, pivotPos + 1, end) {
                return
            }
        }

        pdqLoop(&arr, begin, pivotPos, badAllowed)
        begin = pivotPos + 1
        leftmost = false
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    pdqLoop(&arr, 0, n, pdqLog(n))
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
