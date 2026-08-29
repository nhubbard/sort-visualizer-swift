import Foundation

func ceilLog(_ n: Int) -> Int {
    var i = 0
    while (1 << i) < n {
        i += 1
    }
    return i
}

func multiSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ len: Int) {
    for i in 0 ..< len {
        array.swapAt(a + i, b + i)
    }
}

func insertTo(_ array: inout [Int], _ a: Int, _ b: Int) {
    var a = a
    let temp = array[a]
    while a > b {
        a -= 1
        array[a + 1] = array[a]
    }
    array[b] = temp
}

func binarySearch(_ array: [Int], _ start: Int, _ end: Int, _ value: Int, _ left: Bool) -> Int {
    var a = start
    var b = end
    while a < b {
        let m = a + (b - a) / 2
        let comp = left ? (value <= array[m]) : (value < array[m])
        if comp {
            b = m
        } else {
            a = m + 1
        }
    }
    return a
}

func binaryInsertion(_ array: inout [Int], _ a: Int, _ b: Int) {
    var i = a + 1
    while i < b {
        let value = array[i]
        insertTo(&array, i, binarySearch(array, a, i, value, false))
        i += 1
    }
}

func merge(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ pIn: Int) -> Int {
    var i = a
    var j = m
    var p = pIn
    while i < m, j < b {
        if array[i] <= array[j] {
            array.swapAt(p, i)
            p += 1
            i += 1
        } else {
            array.swapAt(p, j)
            p += 1
            j += 1
        }
    }
    var leftover = 0
    while i < m {
        array.swapAt(p, i)
        p += 1
        i += 1
    }
    while j < b {
        array.swapAt(p, j)
        p += 1
        j += 1
        leftover += 1
    }
    return leftover
}

func mergeWithBufStatic(
    _ array: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ p: Int, _ useBinarySearch: Bool
) {
    var i = 0
    var j = m
    var k = a
    if useBinarySearch {
        while i < m - a, j < b {
            if array[j] < array[p + i] {
                let value = array[p + i]
                let q = binarySearch(array, j, b, value, true)
                while j < q {
                    array.swapAt(k, j)
                    k += 1
                    j += 1
                }
            }
            array.swapAt(k, p + i)
            k += 1
            i += 1
        }
        while i < m - a {
            array.swapAt(k, p + i)
            k += 1
            i += 1
        }
    } else {
        while i < m - a, j < b {
            if array[p + i] <= array[j] {
                array.swapAt(k, p + i)
                k += 1
                i += 1
            } else {
                array.swapAt(k, j)
                k += 1
                j += 1
            }
        }
        while i < m - a {
            array.swapAt(k, p + i)
            k += 1
            i += 1
        }
    }
}

func mergeSort(_ array: inout [Int], _ a: Int, _ p: Int, _ length: Int) {
    var j = 16
    let ceilLogValue = ceilLog(length)
    var pos = (length > 16 && (ceilLogValue & 1) == 1) ? p : a

    var i = pos
    while i + 16 <= pos + length {
        binaryInsertion(&array, i, i + 16)
        i += 16
    }
    binaryInsertion(&array, i, pos + length)

    var nxt = pos
    while j < length {
        pos = nxt
        nxt ^= a ^ p
        var posNext = nxt

        i = pos
        while i + 2 * j <= pos + length {
            merge(&array, i, i + j, i + 2 * j, posNext)
            i += 2 * j
            posNext += 2 * j
        }
        if i + j < pos + length {
            merge(&array, i, i + j, pos + length, posNext)
        } else {
            while i < pos + length {
                array.swapAt(i, posNext)
                i += 1
                posNext += 1
            }
        }
        j *= 2
    }
}

func bufferedMerge(_ array: inout [Int], _ a: Int, _ b: Int) {
    if b - a <= 16 {
        binaryInsertion(&array, a, b)
        return
    }

    var m = (a + b + 1) / 2
    mergeSort(&array, m, 2 * m - b, b - m)

    var n = (a + m + 1) / 2
    let limit = (b - a) / 16
    while m - a > limit {
        mergeSort(&array, 2 * n - m, n, m - n)
        mergeWithBufStatic(&array, n, m, b, 2 * n - m, (b - m) / (m - n) >= ceilLog(n - a))
        m = n
        n = (a + m + 1) / 2
    }

    bufferedMerge(&array, a, m)
    multiSwap(&array, a, b - (m - a), m - a)
    let s = merge(&array, m, b - (m - a), b, a)
    bufferedMerge(&array, b - (m - a) - s, b)
}

func sort(_ array: inout [Int]) {
    let n = array.count
    if n <= 1 {
        return
    }
    bufferedMerge(&array, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
