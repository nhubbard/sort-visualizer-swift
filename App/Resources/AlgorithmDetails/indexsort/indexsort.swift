func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 0 else { return }
    let minValue = arr.min()!

    for i in 0 ..< n {
        var cmpCount = 0
        while arr[i] - minValue != i, cmpCount < n {
            let j = arr[i] - minValue
            arr.swapAt(i, j)
            cmpCount += 1
        }
        if cmpCount >= n - 1 {
            break
        }
    }
}

var array: [Int] = [
    7, 3, 14, 0, 9, 5, 12, 1,
    15, 4, 10, 2, 13, 6, 11, 8,
]
sort(&array)
print(array)
