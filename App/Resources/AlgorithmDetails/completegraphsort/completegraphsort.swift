import Foundation

func compSwap(_ arr: inout [Int], _ a: Int, _ b: Int) {
    if arr[a] > arr[b] {
        arr.swapAt(a, b)
    }
}

func split(_ arr: inout [Int], _ aIn: Int, _ m: Int, _ bIn: Int) {
    var a = aIn
    var b = bIn
    if b - a < 2 {
        return
    }
    var c = 0
    let len1 = (b - a) / 2
    let odd = (b - a) % 2 == 1
    if odd {
        if m - a > b - m {
            c = a
            a += 1
        } else {
            b -= 1
            c = b
        }
    }
    for s in 0 ..< len1 {
        var i = a
        for j in s ..< len1 {
            compSwap(&arr, i, m + j)
            i += 1
        }
        for j in 0 ..< s {
            compSwap(&arr, i, m + j)
            i += 1
        }
    }
    if odd {
        if c < m {
            for j in 0 ..< len1 {
                compSwap(&arr, c, m + j)
            }
        } else {
            for j in 0 ..< len1 {
                compSwap(&arr, a + j, c)
            }
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var d = 2
    let end = 1 << Int(log(Double(n - 1)) / log(2.0) + 1)
    while d <= end {
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
            split(&arr, i, j, k)
            i = k
        }
        d *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
