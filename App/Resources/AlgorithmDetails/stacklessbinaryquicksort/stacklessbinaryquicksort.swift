func mostSignificantBit(_ value: Int) -> Int {
    if value == 0 {
        return -1
    }
    var bit = 0
    while (value >> (bit + 1)) != 0 {
        bit += 1
    }
    return bit
}

func getBit(_ value: Int, _ bit: Int) -> Bool {
    (value >> bit) & 1 == 1
}

func partition(_ arr: inout [Int], _ lo: Int, _ hi: Int, _ bit: Int) -> Int {
    var i = lo - 1
    var j = hi
    while true {
        i += 1
        while i < j && !getBit(arr[i], bit) {
            i += 1
        }
        j -= 1
        while j > i && getBit(arr[j], bit) {
            j -= 1
        }
        if i < j {
            arr.swapAt(i, j)
        } else {
            return i
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n <= 1 {
        return
    }

    let maxValue = arr.max() ?? 0
    var q = mostSignificantBit(maxValue)
    if q < 0 {
        return
    }

    var m = 0
    var i = 0
    var b = n

    while i < n {
        let p = b - i < 1 ? i : partition(&arr, i, b, q)

        if q == 0 {
            m += 2
            while !getBit(m, q + 1) {
                q += 1
            }
            i = b
            while b < n, (arr[b] >> (q + 1)) == (m >> (q + 1)) {
                b += 1
            }
        } else {
            b = p
            q -= 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
