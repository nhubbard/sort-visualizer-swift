func sort(_ arr: inout [Int]) {
    let n = arr.count
    var idx = Array(0 ..< n)

    func isSorted(_ a: [Int]) -> Bool {
        for i in 1 ..< a.count {
            if a[i] < a[i - 1] {
                return false
            }
        }
        return true
    }

    func permute(_ length: Int) -> Bool {
        if length < 2 {
            return isSorted(arr)
        }
        for i in stride(from: length - 2, through: 0, by: -1) {
            if permute(length - 1) {
                return true
            }
            let t1 = arr[idx[i]]
            arr[idx[i]] = arr[idx[length - 1]]
            arr[idx[length - 1]] = t1
            let t2 = idx[i]
            idx[i] = idx[length - 1]
            idx[length - 1] = t2
        }
        if permute(length - 1) {
            return true
        }
        var t = idx[length - 1]
        for i in stride(from: length - 1, through: 1, by: -1) {
            idx[i] = idx[i - 1]
        }
        idx[0] = t
        t = arr[idx[0]]
        for i in 1 ..< length {
            arr[idx[i - 1]] = arr[idx[i]]
        }
        arr[idx[length - 1]] = t
        return false
    }

    permute(n)
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
