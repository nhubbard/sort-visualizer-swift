import Foundation

private var blockSize = 1

func sort(_ array: inout [Int]) {
    blockSize = 1
    while blockSize * blockSize < array.count {
        blockSize *= 2
    }
    synchronousSort(&array, 0, array.count)
}

func multiSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ len: Int) {
    for i in 0 ..< len {
        array.swapAt(a + i, b + i)
    }
}

func rotate(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    var a = a
    var m = m
    var b = b
    var l = m - a
    var r = b - m
    while l > 0, r > 0 {
        if r < l {
            multiSwap(&array, m - r, m, r)
            b -= r
            m -= r
            l -= r
        } else {
            multiSwap(&array, a, m, l)
            a += l
            m += l
            r -= l
        }
    }
}

func binarySearch(_ array: [Int], _ a: Int, _ b: Int, _ value: Int, _ left: Bool) -> Int {
    var a = a
    var b = b
    while a < b {
        let mid = a + (b - a) / 2
        let comp = left ? value <= array[mid] : value < array[mid]
        if comp {
            b = mid
        } else {
            a = mid + 1
        }
    }
    return a
}

func synchronousMerge(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    if m - a <= blockSize, b - m <= blockSize {
        let temp = Array(array[a ..< b])
        var i = 0
        var j = m - a
        for k in a ..< b {
            if i < m - a, j == b - a || temp[i] <= temp[j] {
                array[k] = temp[i]
                i += 1
            } else {
                array[k] = temp[j]
                j += 1
            }
        }
        return
    }
    let m1: Int
    let m3: Int
    var m2: Int
    if m - a >= b - m {
        m1 = a + (m - a) / 2
        let value = array[m1]
        m2 = binarySearch(array, m, b, value, true)
        m3 = m1 + (m2 - m)
    } else {
        m2 = m + (b - m) / 2
        let value = array[m2]
        m1 = binarySearch(array, a, m, value, false)
        m3 = m2 - (m - m1)
        m2 += 1
    }
    rotate(&array, m1, m, m2)
    if m2 - (m3 + 1) > 0, b - m2 > 0 {
        synchronousMerge(&array, m3 + 1, m2, b)
    }
    if m1 - a > 0, m3 - m1 > 0 {
        synchronousMerge(&array, a, m1, m3)
    }
}

func synchronousSort(_ array: inout [Int], _ a: Int, _ b: Int) {
    let len = b - a
    var start = a
    while start < b {
        let end = min(start + 16, b)
        if start + 1 < end {
            for i in (start + 1) ..< end {
                let value = array[i]
                var cursor = i
                while cursor > start, array[cursor - 1] > value {
                    array[cursor] = array[cursor - 1]
                    cursor -= 1
                }
                array[cursor] = value
            }
        }
        start += 16
    }
    var j = 16
    while j < len {
        var i = a
        while i + 2 * j <= b {
            synchronousMerge(&array, i, i + j, i + 2 * j)
            i += 2 * j
        }
        if i + j < b {
            synchronousMerge(&array, i, i + j, b)
        }
        j *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
