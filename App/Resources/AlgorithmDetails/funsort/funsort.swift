func compositeLess(_ arr: [Int], _ key: [Int], _ mid: Int, _ i: Int) -> Bool {
    if arr[mid] < arr[i] {
        return true
    }
    if arr[mid] == arr[i] {
        return key[mid] < key[i]
    }
    return false
}

func binarySearch(_ arr: [Int], _ key: [Int], _ n: Int, _ i: Int) -> Int {
    var start = 0
    var end = n - 1
    while start < end {
        let mid = (start + end) / 2
        if compositeLess(arr, key, mid, i) {
            start = mid + 1
        } else {
            end = mid
        }
    }
    return start
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var key = Array(0 ..< n)

    for i in 1 ..< n {
        var done = false
        while !done {
            let pos = binarySearch(arr, key, n, i)
            if pos == i {
                done = true
            } else if i < pos - 1 {
                arr.swapAt(i, pos - 1)
                key.swapAt(i, pos - 1)
            } else {
                arr.swapAt(i, pos)
                key.swapAt(i, pos)
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
