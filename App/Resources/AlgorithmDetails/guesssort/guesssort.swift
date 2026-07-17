func sort(_ arr: inout [Int]) {
    let n = arr.count
    var loops = [Int](repeating: 0, count: n)
    var indexes = [Int](repeating: 0, count: n)

    func isValid() -> Bool {
        var total = 0
        for i in 0 ..< n {
            for j in 0 ..< n {
                if loops[i] == loops[j] {
                    total += 1
                }
            }
        }
        for i in 0 ..< n {
            for j in 0 ..< n {
                if i < j && arr[loops[i]] > arr[loops[j]] {
                    total += 1
                } else if i > j && arr[loops[i]] < arr[loops[j]] {
                    total += 1
                }
            }
        }
        return total == n
    }

    while true {
        if isValid() {
            indexes = loops
        }
        var pos = 0
        while pos < n {
            if loops[pos] < n - 1 {
                loops[pos] += 1
                break
            } else {
                loops[pos] = 0
                pos += 1
            }
        }
        if pos == n {
            break
        }
    }

    let original = arr
    for i in 0 ..< n {
        arr[i] = original[indexes[i]]
    }
}

var array: [Int] = [0, 39, 21, 14]
sort(&array)
print(array)
