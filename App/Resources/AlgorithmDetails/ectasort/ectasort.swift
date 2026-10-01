func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }
    var run = n
    while run >= 32 {
        run = (run + 1) / 2
    }

    func insertion(_ start: Int, _ end: Int) {
        guard end - start > 1 else { return }
        for index in (start + 1) ..< end {
            let value = arr[index]
            var low = start
            var high = index
            while low < high {
                let middle = low + (high - low) / 2
                if arr[middle] > value {
                    high = middle
                } else {
                    low = middle + 1
                }
            }
            var cursor = index
            while cursor > low {
                arr[cursor] = arr[cursor - 1]; cursor -= 1
            }
            arr[low] = value
        }
    }

    if n <= 32 {
        insertion(0, n); return
    }
    let half = n / 2
    var buffer = Array(arr[half ..< 2 * half])

    func mergeBackward(_ start: Int, _ middle: Int, _ end: Int, _ workspace: Int) {
        let values = Array(arr[middle ..< end])
        for offset in values.indices {
            arr[workspace + offset] = values[offset]
        }
        var left = middle - 1
        var right = workspace + values.count - 1
        var output = end - 1
        while left >= start, right >= workspace {
            if arr[left] > arr[right] {
                arr[output] = arr[left]; left -= 1
            } else {
                arr[output] = arr[right]; right -= 1
            }
            output -= 1
        }
        while right >= workspace {
            arr[output] = arr[right]; right -= 1; output -= 1
        }
    }

    func sortSegment(_ start: Int, _ end: Int, _ workspace: Int) {
        var lower = start
        while lower < end {
            insertion(lower, min(lower + run, end))
            lower += run
        }
        var width = run
        while width < end - start {
            lower = start
            while lower < end {
                let middle = min(lower + width, end)
                let upper = min(lower + 2 * width, end)
                if middle < upper {
                    mergeBackward(lower, middle, upper, workspace)
                }
                lower += 2 * width
            }
            width *= 2
        }
    }

    sortSegment(0, half, half)
    for index in 0 ..< half {
        arr[half + index] = buffer[index]
    }
    buffer = Array(arr[0 ..< half])
    sortSegment(half, n, 0)
    var left = 0
    var right = half
    var output = 0
    while left < half, right < n {
        if buffer[left] <= arr[right] {
            arr[output] = buffer[left]; left += 1
        } else {
            arr[output] = arr[right]; right += 1
        }
        output += 1
    }
    while left < half {
        arr[output] = buffer[left]; left += 1; output += 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
