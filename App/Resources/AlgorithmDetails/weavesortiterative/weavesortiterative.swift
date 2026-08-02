func sort(_ arr: inout [Int]) {
    let end = arr.count

    func compSwap(_ a: Int, _ b: Int) {
        if b < end, arr[a] > arr[b] {
            arr.swapAt(a, b)
        }
    }

    var padded = 1
    while padded < end {
        padded *= 2
    }

    var i = 1
    while i < padded {
        var j = 1
        while j <= i {
            var k = 0
            while k < padded {
                let d = padded / i / 2
                var m = 0
                var l = padded / j - d
                while l >= padded / j / 2 {
                    var p = 0
                    while p < d {
                        compSwap(k + m, k + l + p)
                        p += 1
                        m += 1
                    }
                    l -= d
                }
                k += padded / j
            }
            j *= 2
        }
        i *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
