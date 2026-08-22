func sort(_ arr: inout [Int]) {
    let n = arr.count
    var loops = [Int](repeating: 0, count: n)

    func pairOk(_ i: Int) -> Bool {
        let a = arr[loops[i]]
        let b = arr[loops[i + 1]]
        if a < b {
            return true
        }
        if a == b && loops[i] < loops[i + 1] {
            return true
        }
        return false
    }

    func firstFailure() -> Int {
        var i = n - 2
        while i >= 0 && pairOk(i) {
            i -= 1
        }
        return i
    }

    while true {
        let i = firstFailure()
        if i < 0 {
            break
        }
        var pos = 0
        while pos < n {
            if pos >= i, loops[pos] < n - 1 {
                loops[pos] += 1
                break
            } else {
                loops[pos] = 0
            }
            pos += 1
        }
    }

    var mapped = [Int](repeating: 0, count: n)
    for i in 0 ..< n {
        mapped[i] = arr[loops[i]]
    }
    for i in 0 ..< n {
        arr[i] = mapped[i]
    }
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
