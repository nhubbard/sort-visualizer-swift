func flip(_ arr: inout [Int], _ end: Int) {
    var start = 0
    var e = end
    while start < e {
        arr.swapAt(start, e)
        start += 1
        e -= 1
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    for i in stride(from: n - 1, through: 1, by: -1) {
        var max = 0
        for j in (max + 1) ... i where arr[j] > arr[max] {
            max = j
        }
        if max != i {
            flip(&arr, max)
            flip(&arr, i)
            flip(&arr, i - 1)
            flip(&arr, max - 1)
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
