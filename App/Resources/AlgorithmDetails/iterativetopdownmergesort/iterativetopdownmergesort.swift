func merge(_ array: inout [Int], _ low: Int, _ mid: Int, _ high: Int) {
    let left = Array(array[low ..< mid])
    let right = Array(array[mid ..< high])
    var i = 0
    var j = 0
    var k = low
    while i < left.count, j < right.count {
        if left[i] <= right[j] {
            array[k] = left[i]
            i += 1
        } else {
            array[k] = right[j]
            j += 1
        }
        k += 1
    }
    while i < left.count {
        array[k] = left[i]
        i += 1
        k += 1
    }
    while j < right.count {
        array[k] = right[j]
        j += 1
        k += 1
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
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
            merge(&arr, low, mid, high)
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
