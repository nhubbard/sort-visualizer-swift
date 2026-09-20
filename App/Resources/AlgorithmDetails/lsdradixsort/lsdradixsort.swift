func sort(_ arr: inout [Int]) {
    let n = arr.count
    let maxValue = arr.max() ?? 0
    var output = [Int](repeating: 0, count: n)
    var divisor = 1
    while true {
        var counts = [Int](repeating: 0, count: 4)
        for value in arr { counts[(value / divisor) % 4] += 1 }
        for digit in 1 ..< 4 { counts[digit] += counts[digit - 1] }
        for i in stride(from: n - 1, through: 0, by: -1) {
            let digit = (arr[i] / divisor) % 4
            counts[digit] -= 1
            output[counts[digit]] = arr[i]
        }
        for i in 0 ..< n { arr[i] = output[i] }
        if divisor > maxValue / 4 { break }
        divisor *= 4
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
