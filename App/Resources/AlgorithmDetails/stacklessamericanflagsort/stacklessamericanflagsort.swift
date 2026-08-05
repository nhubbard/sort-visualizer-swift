let radix = 4

func getDigit(_ value: Int, _ place: Int) -> Int {
    var value = value
    for _ in 0 ..< place {
        value /= radix
    }
    return value % radix
}

func shift(_ value: Int, _ places: Int) -> Int {
    var value = value
    for _ in 0 ..< places {
        value /= radix
    }
    return value
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }

    var q = 0
    var probe = radix
    let maxValue = arr.max() ?? 0
    while probe <= maxValue {
        q += 1
        probe *= radix
    }

    var counts = [Int](repeating: 0, count: radix)
    var offsets = [Int](repeating: 0, count: radix)

    func bump(_ digit: Int) {
        counts[digit] += 1
    }

    /// Turns the raw per-bucket counts already accumulated in `counts` into
    /// starting offsets, then places every element in [start, end) by
    /// following displacement cycles, one bucket at a time.
    func distribute(_ start: Int, _: Int, _ place: Int) -> Int {
        for i in 1 ..< radix {
            counts[i] += counts[i - 1]
            offsets[i] = counts[i - 1]
        }

        for bucket in 0 ..< (radix - 1) {
            let position = start + offsets[bucket]
            if counts[bucket] > offsets[bucket] {
                var held = arr[position]
                repeat {
                    let digit = getDigit(held, place)
                    counts[digit] -= 1
                    let displaced = arr[start + counts[digit]]
                    arr[start + counts[digit]] = held
                    held = displaced
                } while counts[bucket] > offsets[bucket]
            }
        }

        let split = start + offsets[1]
        for i in 0 ..< radix {
            counts[i] = 0
            offsets[i] = 0
        }
        return split
    }

    // `i`/`b` track the bounds of whichever range is currently active, `q`
    // the digit place being distributed on, and `m` a counter that mirrors
    // how many bucket boundaries have already been walked at the current
    // depth, standing in for the call stack a recursive walk would need.
    var m = 0
    var i = 0
    var b = n

    for j in i ..< b {
        bump(getDigit(arr[j], q))
    }

    while i < n {
        let p = b - i < 1 ? i : distribute(i, b, q)

        if q == 0 {
            m += radix
            var t = m / radix
            while t % radix == 0 {
                t /= radix
                q += 1
            }

            i = b
            while b < n, shift(arr[b], q + 1) == shift(m, q + 1) {
                bump(getDigit(arr[b], q))
                b += 1
            }
        } else {
            b = p
            q -= 1
            for j in i ..< b {
                bump(getDigit(arr[j], q))
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
