func sort(_ arr: inout [Int]) {
    let end = arr.count
    var i = 0
    while i < end - 1 {
        if arr[i] > arr[i + 1] {
            for f in i..<(end - 1) {
                arr.swapAt(f, f + 1)
            }
            if i > 0 {
                i -= 1
            }
            continue
        }
        i += 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
