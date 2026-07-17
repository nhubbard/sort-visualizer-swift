func sort(_ arr: inout [Int]) {
    let n = arr.count

    func idx(_ p: Int) -> Int {
        return n - p
    }

    func siftDown(_ root: Int, _ dist: Int) {
        var root = root
        while root <= dist / 2 {
            var leaf = 2 * root
            if leaf < dist && arr[idx(leaf)] > arr[idx(leaf + 1)] {
                leaf += 1
            }
            if arr[idx(root)] > arr[idx(leaf)] {
                arr.swapAt(idx(root), idx(leaf))
                root = leaf
            } else {
                break
            }
        }
    }

    var i = n / 2
    while i >= 1 {
        siftDown(i, n)
        i -= 1
    }

    i = n
    while i > 1 {
        arr.swapAt(idx(1), idx(i))
        siftDown(1, i - 1)
        i -= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
