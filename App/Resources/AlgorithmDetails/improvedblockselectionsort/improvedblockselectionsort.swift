import Foundation

func blockRoot(_ n: Int) -> Int {
    var i = 1
    while i * i < n {
        i *= 2
    }
    return i
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

func selectRange(_ array: [Int], _ start: Int, _ end: Int, _ bLen: Int) -> Int {
    var minIndex = start
    var a = start + bLen
    while a < end {
        if array[a] < array[minIndex] {
            minIndex = a
        } else if array[a] == array[minIndex] && array[a + bLen - 1] < array[minIndex + bLen - 1] {
            minIndex = a
        }
        a += bLen
    }
    return minIndex
}

func blockSelect(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ bLen: Int) {
    var k = a
    var j = m
    while k < m, array[k] <= array[m] {
        k += bLen
    }
    guard k != m else { return }

    var i = m
    multiSwap(&array, k, j, bLen)
    k += bLen
    j += bLen

    while k < j, j < b {
        if array[i] <= array[j] {
            if k != i {
                multiSwap(&array, k, i, bLen)
            }
            k += bLen
            i = selectRange(array, max(m, k), j, bLen)
        } else {
            if i == k {
                i = j
            }
            if k != j {
                multiSwap(&array, k, j, bLen)
            }
            k += bLen
            j += bLen
        }
    }

    while k < j {
        i = selectRange(array, k, b, bLen)
        if k != i {
            multiSwap(&array, k, i, bLen)
        }
        k += bLen
    }
}

func inPlaceMerge(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) -> Int {
    var i = a
    var j = m
    while i < j && j < b {
        if array[i] > array[j] {
            var k = j + 1
            while k < b && array[i] > array[k] {
                k += 1
            }
            rotate(&array, i, j, k)
            i += k - j
            j = k
        } else {
            i += 1
        }
    }
    return i
}

func inPlaceMergeBW(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    var i = m - 1
    var j = b - 1
    while j > i, i >= a {
        if array[i] > array[j] {
            var k = i - 1
            while k >= a, array[k] > array[j] {
                k -= 1
            }
            rotate(&array, k + 1, i + 1, j + 1)
            j -= i - k
            i = k
        } else {
            j -= 1
        }
    }
}

func sort(_ array: inout [Int]) {
    let n = array.count
    if n <= 1 {
        return
    }
    var j = 1
    while j < n {
        var bLen = blockRoot(j)
        var runLength = j
        let b = n - n % bLen

        while runLength > 16 {
            var i = 0
            while i + j < b {
                var k = i
                while k + runLength < min(i + 2 * j, b) {
                    blockSelect(&array, k, k + runLength, min(k + 2 * runLength, b), bLen)
                    k += runLength
                }
                i += 2 * j
            }
            runLength = bLen
            bLen = blockRoot(bLen)
        }

        var i = 0
        while i + j < b {
            var k = i
            var f = i
            while k + runLength < min(i + 2 * j, b) {
                f = inPlaceMerge(&array, f, k + runLength, min(k + 2 * runLength, b))
                k += runLength
            }
            i += 2 * j
        }

        inPlaceMergeBW(&array, n - n % (2 * j), b, n)
        j *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
