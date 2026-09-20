func sort(_ arr: inout [Int]) {
    var scratch = Array(repeating: 0, count: arr.count)

    func mergeSort(_ start: Int, _ end: Int) {
        guard end - start > 1 else { return }
        let middle = (start + end) / 2
        mergeSort(start, middle)
        mergeSort(middle, end)
        var left = start
        var right = middle
        var dest = start
        while left < middle, right < end {
            if arr[left] <= arr[right] {
                scratch[dest] = arr[left]
                left += 1
            } else {
                scratch[dest] = arr[right]
                right += 1
            }
            dest += 1
        }
        while left < middle {
            scratch[dest] = arr[left]
            left += 1
            dest += 1
        }
        while right < end {
            scratch[dest] = arr[right]
            right += 1
            dest += 1
        }
        for i in start ..< end {
            arr[i] = scratch[i]
        }
    }

    var start = 0
    var end = arr.count
    while end - start > 16 {
        let pivot = [arr[start], arr[(start + end - 1) / 2], arr[end - 1]].sorted()[1]
        var left = start
        var right = end - 1
        while left <= right {
            while left <= right, arr[left] < pivot {
                left += 1
            }
            while left <= right, arr[right] > pivot {
                right -= 1
            }
            if left <= right {
                arr.swapAt(left, right)
                left += 1
                right -= 1
            }
        }
        if left == start || left == end {
            mergeSort(start, end)
            return
        }
        if left - start <= end - left {
            mergeSort(start, left)
            start = left
        } else {
            mergeSort(left, end)
            end = left
        }
    }

    guard end - start > 1 else { return }
    for i in (start + 1) ..< end {
        let value = arr[i]
        var j = i
        while j > start, arr[j - 1] > value {
            arr[j] = arr[j - 1]
            j -= 1
        }
        arr[j] = value
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
    10, 2, 95, 46, 21, 74, 6, 38,
]
sort(&array)
print(array)
