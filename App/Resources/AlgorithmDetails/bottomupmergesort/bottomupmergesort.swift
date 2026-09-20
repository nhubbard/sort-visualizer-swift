import Foundation

func merge(_ arr: [Int], _ scratch: inout [Int], _ n: Int, _ index: Int, _ mergeSize: Int) -> Int? {
    let mid = index + mergeSize / 2
    let end = min(n, index + mergeSize)
    if mid >= end { return index }
    var left = index, right = mid, out = index
    while left < mid && right < end {
        if arr[left] <= arr[right] { scratch[out] = arr[left]; left += 1 }
        else { scratch[out] = arr[right]; right += 1 }
        out += 1
    }
    while left < mid { scratch[out] = arr[left]; left += 1; out += 1 }
    while right < end { scratch[out] = arr[right]; right += 1; out += 1 }
    return nil
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 { return }
    var scratch = arr
    var mergeSize = 2
    while mergeSize <= n {
        var copyLength = n
        var index = 0
        while index < n {
            if let stop = merge(arr, &scratch, n, index, mergeSize) { copyLength = stop }
            index += mergeSize
        }
        for j in 0..<copyLength { arr[j] = scratch[j] }
        mergeSize *= 2
    }
    if mergeSize / 2 != n {
        let copyLength = merge(arr, &scratch, n, 0, mergeSize) ?? n
        for j in 0..<copyLength { arr[j] = scratch[j] }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
