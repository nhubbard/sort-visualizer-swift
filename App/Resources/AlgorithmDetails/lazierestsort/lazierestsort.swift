func sort(_ arr: inout [Int]) {
    let n = arr.count
    func reverse(_ a: Int, _ b: Int) {
        var i = a, j = b - 1
        while i < j {
            arr.swapAt(i, j); i += 1; j -= 1
        }
    }
    func rotate(_ a: Int, _ m: Int, _ b: Int) {
        reverse(a, m); reverse(m, b); reverse(a, b)
    }
    func lower(_ start: Int, _ end: Int, _ value: Int) -> Int {
        var a = start, b = end
        while a < b {
            let mid = (a + b) / 2
            if value <= arr[mid] {
                b = mid
            } else {
                a = mid + 1
            }
        }
        return a
    }
    func upper(_ start: Int, _ end: Int, _ value: Int) -> Int {
        var a = start, b = end
        while a < b {
            let mid = (a + b) / 2
            if value < arr[mid] {
                b = mid
            } else {
                a = mid + 1
            }
        }
        return a
    }
    func leftGallop(_ a: Int, _ b: Int, _ value: Int) -> Int {
        var step = 1
        while a - 1 + step < b && value > arr[a - 1 + step] {
            step *= 2
        }
        return lower(a + step / 2, min(b, a - 1 + step), value)
    }
    func rightGallop(_ a: Int, _ b: Int, _ value: Int) -> Int {
        var step = 1
        while b - step >= a && value < arr[b - step] {
            step *= 2
        }
        return upper(max(a, b - step + 1), b - step / 2, value)
    }
    func insertion(_ a: Int, _ b: Int) {
        guard b - a > 1 else { return }
        for i in (a + 1) ..< b {
            let value = arr[i], position = upper(a, i, value)
            var j = i
            while j > position {
                arr[j] = arr[j - 1]; j -= 1
            }
            arr[position] = value
        }
    }
    func forward(_ a: Int, _ m: Int, _ b: Int) {
        var i = a, j = m
        while i < j, j < b {
            if arr[i] > arr[j] {
                let k = leftGallop(j + 1, b, arr[i])
                rotate(i, j, k)
                i += k - j; j = k
            } else {
                i += 1
            }
        }
    }
    func backward(_ a: Int, _ m: Int, _ b: Int) {
        var i = m - 1, j = b - 1
        while j > i, i >= a {
            if arr[i] > arr[j] {
                let k = rightGallop(a, i, arr[j])
                rotate(k, i + 1, j + 1)
                j -= i + 1 - k; i = k - 1
            } else {
                j -= 1
            }
        }
    }
    func merge(_ a: Int, _ m: Int, _ b: Int) {
        if b - m < m - a {
            backward(a, m, b)
        } else {
            forward(a, m, b)
        }
    }
    func fragmented(_ start: Int, _ middle: Int, _ end: Int, _ size: Int) {
        var a = start, m = middle
        var i = a + (m - a) % size
        while i < m {
            let j = leftGallop(m, end, arr[i])
            rotate(i, m, j)
            let length = j - m, boundary = i
            i += length; m += length
            merge(a, boundary, i)
            a = i; i += size
        }
        merge(max(a, i - size), i, end)
    }
    if n <= 16 {
        insertion(0, n); return
    }
    var size = 1
    while size * size * size < n {
        size += 1
    }
    let group = size * size
    var i = n % size
    while i <= n {
        insertion(max(0, i - size), i); i += size
    }
    i = n - size
    var j = n
    while i > 0 {
        if j - i == group {
            j -= group; i -= size
        }
        forward(max(0, i - size), i, j)
        i -= size
    }
    i = n - group
    while i > 0 {
        fragmented(max(0, i - group), i, n, size); i -= group
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
    10, 2, 95, 46, 21, 74, 6, 38,
]
sort(&array)
print(array)
