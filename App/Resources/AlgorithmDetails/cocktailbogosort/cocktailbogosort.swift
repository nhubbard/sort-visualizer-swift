func isMinimum(_ arr: [Int], _ start: Int, _ end: Int) -> Bool {
    for k in (start + 1) ..< end {
        if arr[start] > arr[k] {
            return false
        }
    }
    return true
}

func isMaximum(_ arr: [Int], _ start: Int, _ end: Int) -> Bool {
    for k in start ..< (end - 1) {
        if arr[k] > arr[end - 1] {
            return false
        }
    }
    return true
}

func shuffleRange(_ arr: inout [Int], _ start: Int, _ end: Int) {
    for i in start ..< (end - 1) {
        let j = Int.random(in: i ..< end)
        arr.swapAt(i, j)
    }
}

func sort(_ arr: inout [Int]) {
    var lo = 0
    var hi = arr.count
    while lo < hi - 1 {
        if isMinimum(arr, lo, hi) {
            lo += 1
        } else if isMaximum(arr, lo, hi) {
            hi -= 1
        } else {
            shuffleRange(&arr, lo, hi)
        }
    }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
