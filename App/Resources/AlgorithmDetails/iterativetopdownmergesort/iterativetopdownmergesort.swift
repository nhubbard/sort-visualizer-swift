func merge(_ array: inout [Int], _ scratch: inout [Int], _ low: Int, _ mid: Int, _ high: Int) {
    var left = low
    var right = mid
    var out = low
    while left < mid && right < high {
        if array[left] <= array[right] {
            scratch[out] = array[left]
            left += 1
        } else {
            scratch[out] = array[right]
            right += 1
        }
        out += 1
    }
    while left < mid {
        scratch[out] = array[left]
        left += 1
        out += 1
    }
    while right < high {
        scratch[out] = array[right]
        right += 1
        out += 1
    }
    for i in low ..< high { array[i] = scratch[i] }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }
    var scratch = [Int](repeating: 0, count: n)
    var subarrayCount = 1
    while subarrayCount < n {
        subarrayCount *= 2
    }

    while subarrayCount > 1 {
        var i = 0
        while i < subarrayCount {
            let low = n * i / subarrayCount
            let mid = n * (i + 1) / subarrayCount
            let high = n * (i + 2) / subarrayCount
            merge(&arr, &scratch, low, mid, high)
            i += 2
        }
        subarrayCount /= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
