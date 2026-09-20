func sort(_ arr: inout [Int]) {
    let n = arr.count
    for i in 1 ..< n {
        var j = i
        while j > 0, arr[j - 1] > arr[j] {
            arr.swapAt(j, j - 1)
            j -= 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
