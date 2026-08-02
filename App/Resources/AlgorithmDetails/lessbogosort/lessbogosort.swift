func isMinimum(_ arr: [Int], _ start: Int, _ end: Int) -> Bool {
    for k in (start + 1) ..< end {
        if arr[start] > arr[k] {
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
    let n = arr.count
    for i in 0 ..< n {
        while !isMinimum(arr, i, n) {
            shuffleRange(&arr, i, n)
        }
    }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
