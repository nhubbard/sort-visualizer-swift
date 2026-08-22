func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 0 else {
        return
    }

    let maxValue = arr.max()!
    var transpose = [Int](repeating: 0, count: maxValue)

    for i in 0 ..< n {
        let value = arr[i]
        for j in 0 ..< value {
            transpose[j] += 1
        }
    }

    for i in 0 ..< n {
        var total = 0
        for j in 0 ..< maxValue {
            if transpose[j] > 0 {
                total += 1
            }
        }
        arr[n - i - 1] = total
        for j in 0 ..< maxValue {
            transpose[j] -= 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
