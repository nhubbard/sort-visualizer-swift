func digitAt(_ value: Int, _ divisor: Int, _ radix: Int) -> Int {
    (value / divisor) % radix
}

func flagSort(_ arr: inout [Int], _ low: Int, _ high: Int, _ divisor: Int, _ radix: Int) {
    if high - low <= 1 {
        return
    }

    var count = [Int](repeating: 0, count: radix)
    var offset = [Int](repeating: 0, count: radix)

    for i in low ..< high {
        count[digitAt(arr[i], divisor, radix)] += 1
    }

    offset[0] = low
    for d in 1 ..< radix {
        offset[d] = offset[d - 1] + count[d - 1]
    }
    let bucketStart = offset

    for d in 0 ..< radix {
        while count[d] > 0 {
            let origin = offset[d]
            var from = origin
            var value = arr[from]

            repeat {
                let digit = digitAt(value, divisor, radix)
                let dest = offset[digit]
                offset[digit] += 1
                count[digit] -= 1
                let displaced = arr[dest]
                arr[dest] = value
                value = displaced
                from = dest
            } while from != origin
        }
    }

    if divisor > 1 {
        for d in 0 ..< radix {
            let begin = bucketStart[d]
            let end = offset[d]
            if end - begin > 1 {
                flagSort(&arr, begin, end, divisor / radix, radix)
            }
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n <= 1 {
        return
    }

    let radix = 10
    let maxValue = arr.max() ?? 0

    var divisor = 1
    while maxValue / divisor >= radix {
        divisor *= radix
    }

    flagSort(&arr, 0, n, divisor, radix)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
