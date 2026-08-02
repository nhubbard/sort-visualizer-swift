import Foundation

func compSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
    if b < end, array[a] > array[b] {
        array.swapAt(a, b)
    }
}

func sort(_ arr: inout [Int]) {
    let length = arr.count
    let end = length

    var n = 1
    while n < length {
        n <<= 1
    }

    var k = n >> 1
    while k > 0 {
        var j = 0
        while j < length {
            for i in 0 ..< k {
                compSwap(&arr, j + i, j + k + i, end)
            }
            j += k << 1
        }
        k >>= 1
    }

    k = 2
    while k < n {
        var m = k >> 1
        while m > 0 {
            var j = 0
            while j < length {
                var p = m
                while p < ((k - m) << 1) {
                    for i in 0 ..< m {
                        compSwap(&arr, j + p + i, j + p + m + i, end)
                    }
                    p += m << 1
                }
                j += k << 1
            }
            m >>= 1
        }
        k <<= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
