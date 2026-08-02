func compSwap(_ arr: inout [Int], _ a: Int, _ b: Int) {
    if arr[a] > arr[b] {
        arr.swapAt(a, b)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var p = 1
    while p < n {
        p *= 2
    }

    var m = 4
    while m <= p {
        for k in 0 ..< (m / 2) {
            let cnt = k <= m / 4 ? k : m / 2 - k
            var j = 0
            while j < n {
                if j + cnt + 1 < n {
                    var i = j + cnt
                    while i + 1 < min(n, j + m - cnt) {
                        compSwap(&arr, i, i + 1)
                        i += 2
                    }
                }
                j += m
            }
        }
        m *= 2
    }
    m /= 2
    for k in 0 ... (m / 2) {
        var i = k
        while i + 1 < min(n, m - k) {
            compSwap(&arr, i, i + 1)
            i += 2
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
