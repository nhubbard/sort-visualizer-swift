func sort(_ arr: inout [Int]) {
    let n = arr.count
    let gaps = [8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1]
    for gap in gaps where gap < n {
        for i in gap ..< n {
            var j = i
            while j >= gap && arr[j] < arr[j - gap] {
                arr.swapAt(j, j - gap)
                j -= gap
            }
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
