func sort(_ arr: inout [Int]) {
    let n = arr.count
    var loops = [Int](repeating: 0, count: n)

    func isValid() -> Bool {
        for i in 0 ..< (n - 1) {
            let a = arr[loops[i]]
            let b = arr[loops[i + 1]]
            if a < b || (a == b && loops[i] < loops[i + 1]) {
                continue
            }
            return false
        }
        return true
    }

    while !isValid() {
        for pos in 0 ..< n {
            if loops[pos] < n - 1 {
                loops[pos] += 1
                break
            } else {
                loops[pos] = 0
            }
        }
    }

    let mapped = loops.map { arr[$0] }
    for i in 0 ..< n {
        arr[i] = mapped[i]
    }
}

var array: [Int] = [0, 39, 21, 62, 14]
sort(&array)
print(array)
