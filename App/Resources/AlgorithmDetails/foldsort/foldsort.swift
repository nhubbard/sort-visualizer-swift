func compSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
    if b < end, arr[a] > arr[b] {
        arr.swapAt(a, b)
    }
}

func halver(_ arr: inout [Int], _ low: Int, _ high: Int, _ end: Int) {
    var lo = low
    var hi = high
    while lo < hi {
        compSwap(&arr, lo, hi, end)
        lo += 1
        hi -= 1
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var ceilLog = 1
    while (1 << ceilLog) < n {
        ceilLog += 1
    }
    let end = n
    let size2 = 1 << ceilLog

    var k = size2 >> 1
    while k > 0 {
        var i = size2
        while i >= k {
            var j = 0
            while j < end {
                halver(&arr, j, j + i - 1, end)
                j += i
            }
            i >>= 1
        }
        k >>= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
