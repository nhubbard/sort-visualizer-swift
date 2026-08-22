func intPow(_ base: Int, _ exponent: Int) -> Int {
    var result = 1
    for _ in 0 ..< exponent {
        result *= base
    }
    return result
}

func getDigit(_ value: Int, _ power: Int, _ radix: Int) -> Int {
    (value / intPow(radix, power)) % radix
}

func multiSwap(_ arr: inout [Int], _ pos: Int, _ to: Int) {
    if to > pos {
        for k in pos ..< to {
            arr.swapAt(k, k + 1)
        }
    } else if to < pos {
        var k = pos
        while k > to {
            arr.swapAt(k, k - 1)
            k -= 1
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n == 0 {
        return
    }
    let radix = 4
    let maxValue = arr.max() ?? 0

    var maxPower = 0
    var probe = radix
    while probe <= maxValue {
        maxPower += 1
        probe *= radix
    }

    var vregs = [Int](repeating: 0, count: radix - 1)

    for power in 0 ... maxPower {
        for i in 0 ..< vregs.count {
            vregs[i] = n - 1
        }

        var pos = 0
        for _ in 0 ..< n {
            let digit = getDigit(arr[pos], power, radix)
            if digit == 0 {
                pos += 1
            } else {
                let to = vregs[digit - 1]
                multiSwap(&arr, pos, to)
                var j = digit - 1
                while j > 0 {
                    vregs[j - 1] -= 1
                    j -= 1
                }
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
