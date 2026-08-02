func isSorted(_ arr: [Int]) -> Bool {
    for i in 1 ..< arr.count {
        if arr[i - 1] > arr[i] {
            return false
        }
    }
    return true
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    while !isSorted(arr) {
        let index = Int.random(in: 0 ... (n - 2))
        if arr[index] > arr[index + 1] {
            arr.swapAt(index, index + 1)
        }
    }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
