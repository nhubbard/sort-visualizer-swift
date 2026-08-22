func sort(_ arr: inout [Int]) {
    let n = arr.count

    func maxToFront(_ a: Int, _ b: Int) {
        var best = a
        var i = a + 1
        while i < b {
            if arr[i] > arr[best] {
                best = i
            }
            i += 1
        }
        arr.swapAt(best, a)
    }

    let s = Int(Double(n - 1).squareRoot()) + 1

    var i = 0
    while i < n {
        maxToFront(i, min(i + s, n))
        i += s
    }

    var j = n
    while j > 0 {
        var best = 0
        var k = best + s
        while k < j {
            if arr[k] >= arr[best] {
                best = k
            }
            k += s
        }
        j -= 1
        arr.swapAt(best, j)
        maxToFront(best, min(best + s, j))
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
