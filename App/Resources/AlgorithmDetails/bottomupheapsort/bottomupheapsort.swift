func sort(_ arr: inout [Int]) {
    let n = arr.count

    func siftDown(_ i: Int, _ b: Int) {
        var j = i
        while 2 * j + 1 < b {
            if 2 * j + 2 < b {
                j = arr[2 * j + 2] > arr[2 * j + 1] ? 2 * j + 2: 2 * j + 1
            } else {
                j = 2 * j + 1
            }
        }
        while arr[i] > arr[j] {
            j = (j - 1) / 2
        }
        while j > i {
            arr.swapAt(i, j)
            j = (j - 1) / 2
        }
    }

    for i in stride(from: (n - 1) / 2, through: 0, by: -1) {
        siftDown(i, n)
    }

    for i in stride(from: n - 1, through: 1, by: -1) {
        arr.swapAt(0, i)
        siftDown(0, i)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
