func push(_ array: inout [Int], _ p: Int, _ a: Int, _ b: Int) {
    if a == b {
        return
    }
    let temp = array[p]
    array[p] = array[a]
    for i in (a + 1) ..< b {
        array[i - 1] = array[i]
    }
    array[b - 1] = temp
}

func merge(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    var i = a
    var j = m
    while i < m, j < b {
        if array[i] > array[j] {
            j += 1
        } else {
            push(&array, i, m, j)
            i += 1
        }
    }
    while i < m {
        push(&array, i, m, b)
        i += 1
    }
}

func mergeSort(_ array: inout [Int], _ a: Int, _ b: Int) {
    let m = a + (b - a) / 2
    if b - a > 2 {
        if b - a > 3 {
            mergeSort(&array, a, m)
        }
        mergeSort(&array, m, b)
    }
    merge(&array, a, m, b)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    mergeSort(&arr, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
