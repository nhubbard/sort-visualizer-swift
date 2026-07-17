func sort(_ arr: inout [Int]) {
    let n = arr.count
    var ext = arr
    var minValue = ext[0]
    var maxValue = ext[0]
    for k in 0 ..< n {
        if ext[k] < minValue {
            minValue = ext[k]
        }
        if ext[k] > maxValue {
            maxValue = ext[k]
        }
    }
    maxValue += 1

    var cur = minValue
    var i = 0
    while i < n {
        for j in 0 ..< n {
            if ext[j] <= cur {
                arr[i] = ext[j]
                ext[j] = maxValue
                i += 1
            }
        }
        cur += 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
