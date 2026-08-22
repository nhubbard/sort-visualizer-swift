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

func partition(_ arr: inout [Int], _ p: Int, _ r: Int, _ bit: Int) -> Int {
    var i = p - 1
    var j = r + 1
    while true {
        i += 1
        while i <= r && ((arr[i] >> bit) & 1) == 0 {
            i += 1
        }
        j -= 1
        while j >= p && ((arr[j] >> bit) & 1) == 1 {
            j -= 1
        }
        if i < j {
            arr.swapAt(i, j)
        } else {
            return j
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    let maxValue = arr.max() ?? 0
    let bit = mostSignificantBit(maxValue)

    var tasks: [(p: Int, r: Int, bit: Int)] = [(0, n - 1, bit)]
    var head = 0
    while head < tasks.count {
        let t = tasks[head]
        head += 1
        if t.p < t.r, t.bit >= 0 {
            let q = partition(&arr, t.p, t.r, t.bit)
            tasks.append((t.p, q, t.bit - 1))
            tasks.append((q + 1, t.r, t.bit - 1))
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
