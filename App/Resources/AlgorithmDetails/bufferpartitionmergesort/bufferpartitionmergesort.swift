func sort(_ arr: inout [Int]) {
    let run = 8
    for start in stride(from: 0, to: arr.count, by: run) {
        let end = min(start + run, arr.count)
        guard end - start > 1 else { continue }
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

    var scratch = arr
    var width = run
    while width < arr.count {
        for start in stride(from: 0, to: arr.count, by: 2 * width) {
            let middle = min(start + width, arr.count)
            let end = min(start + 2 * width, arr.count)
            var left = start
            var right = middle
            for out in start ..< end {
                if left < middle, right >= end || arr[left] < arr[right] {
                    scratch[out] = arr[left]
                    left += 1
                } else {
                    scratch[out] = arr[right]
                    right += 1
                }
            }
        }
        arr = scratch
        width *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
