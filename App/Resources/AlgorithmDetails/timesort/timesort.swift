func sort(_ a: inout [Int]) {
    let n = a.count
    guard n > 1 else { return }
    var scratch = a, buffer = a
    func mergeSort(_ lo: Int, _ hi: Int) {
        guard hi - lo > 1 else { return }
        let mid = lo + (hi - lo) / 2
        mergeSort(lo, mid)
        mergeSort(mid, hi)
        var left = lo, right = mid, dest = lo
        while left < mid, right < hi {
            if scratch[left] <= scratch[right] {
                buffer[dest] = scratch[left]; left += 1
            } else {
                buffer[dest] = scratch[right]; right += 1
            }
            dest += 1
        }
        while left < mid {
            buffer[dest] = scratch[left]; left += 1; dest += 1
        }
        while right < hi {
            buffer[dest] = scratch[right]; right += 1; dest += 1
        }
        for i in lo ..< hi {
            scratch[i] = buffer[i]
        }
    }
    mergeSort(0, n)
    for i in 0 ..< n {
        a[i] = scratch[i]
    }
    for i in 1 ..< n {
        var j = i
        while j > 0, a[j - 1] > a[j] {
            a.swapAt(j - 1, j); j -= 1
        }
    }
}

var array = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
