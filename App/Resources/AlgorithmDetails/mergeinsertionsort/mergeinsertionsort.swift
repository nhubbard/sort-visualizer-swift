func sort(_ arr: inout [Int]) {
    let length = arr.count
    if length < 2 { return }
    func blockSwap(_ a: Int, _ b: Int, _ size: Int) {
        for offset in 0..<size { arr.swapAt(a - size + 1 + offset, b - size + 1 + offset) }
    }
    func blockInsert(_ end: Int, _ target: Int, _ size: Int) {
        var end = end
        while end - size >= target { blockSwap(end - size, end, size); end -= size }
    }
    func blockReversal(_ start: Int, _ end: Int, _ size: Int) {
        var start = start, end = end - size
        while end > start { blockSwap(start, end, size); start += size; end -= size }
    }
    func blockSearch(_ start: Int, _ end: Int, _ size: Int, _ value: Int) -> Int {
        var start = start, end = end
        while start < end {
            let mid = start + (((end - start) / size) / 2) * size
            if value < arr[mid] { end = mid } else { start = mid + size }
        }
        return start
    }
    func order(_ a: Int, _ b: Int, _ size: Int) {
        var i = a, j = i + size
        while j < b { blockInsert(j, i, size); i += size; j += 2 * size }
        let mid = a + (((b - a) / size) / 2) * size
        blockReversal(mid, b, size)
    }
    var k = 1
    while 2 * k <= length {
        var i = 2 * k - 1
        while i < length {
            if arr[i - k] > arr[i] { blockSwap(i - k, i, k) }
            i += 2 * k
        }
        k *= 2
    }
    while k > 0 {
        let a = k - 1
        var i = a + 2 * k, g = 2, p = 4
        while i + 2 * k * g - k <= length {
            order(i, i + 2 * k * g - k, k)
            let b = a + k * (p - 1)
            i += k * g - k
            var j = i
            while j < i + k * g {
                blockInsert(j, blockSearch(a, b, k, arr[j]), k)
                j += k
            }
            i += k * g + k
            g = p - g
            p *= 2
        }
        while i < length {
            blockInsert(i, blockSearch(a, i, k, arr[i]), k)
            i += 2 * k
        }
        k /= 2
    }
}

var array: [Int] = [
    34, 7, 23, 90, 12, 56, 3, 45, 78, 21, 66, 9,
    50, 15, 88, 40, 61, 5, 33, 72, 18, 95, 27, 60,
]
sort(&array)
print(array)
