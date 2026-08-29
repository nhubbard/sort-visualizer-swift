import Foundation

func insertTo(_ array: inout [Int], _ a: Int, _ b: Int) {
    let temp = array[a]
    var a = a
    while a > b {
        a -= 1
        array[a + 1] = array[a]
    }
    array[b] = temp
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

func bitReversal(_ array: inout [Int], _ a: Int, _ b: Int) {
    let len = b - a
    var m = 0
    let d1 = len >> 1
    let d2 = d1 + (d1 >> 1)
    var i = 1
    while i < len - 1 {
        var j = d1
        var k = i
        var nn = d2
        while k & 1 == 0 {
            j -= nn
            k >>= 1
            nn >>= 1
        }
        m += j
        if m > i {
            array.swapAt(a + i, a + m)
        }
        i += 1
    }
}

func weaveInsert(_ array: inout [Int], _ a: Int, _ b: Int, _ rightInit: Bool) {
    var right = rightInit
    var i = a
    var j = a + 1
    while j < b {
        if right {
            while i < j, array[i] <= array[j] {
                i += 1
            }
        } else {
            while i < j, array[i] < array[j] {
                i += 1
            }
        }
        if i == j {
            right.toggle()
            j += 1
        } else {
            insertTo(&array, j, i)
            i += 1
            j += 2
        }
    }
}

func weaveMerge(_ array: inout [Int], _ a: Int, _ mInit: Int, _ b: Int) {
    if b - a < 2 {
        return
    }
    var a1 = a
    var b1 = b
    var right = true
    if (b - a) % 2 == 1 {
        if mInit - a < b - mInit {
            a1 -= 1
            right = false
        } else {
            b1 += 1
        }
    }
    var e = b1
    while e - a1 > 2 {
        var m = (a1 + e) / 2
        var p = 1
        while p * 2 <= m - a1 {
            p *= 2
        }
        rotate(&array, m - p, m, e - p)
        m = e - p
        let f = m - p
        bitReversal(&array, f, m)
        bitReversal(&array, m, e)
        bitReversal(&array, f, e)
        e = f
    }
    weaveInsert(&array, a, b, right)
}

func sort(_ array: inout [Int]) {
    let n = array.count
    if n <= 1 {
        return
    }
    var d = 1
    while d < n {
        d <<= 1
    }
    while d > 1 {
        var i = 0
        var dec = 0
        while i < n {
            var j = i
            dec += n
            while dec >= d {
                dec -= d
                j += 1
            }
            var k = j
            dec += n
            while dec >= d {
                dec -= d
                k += 1
            }
            weaveMerge(&array, i, j, k)
            i = k
        }
        d /= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
