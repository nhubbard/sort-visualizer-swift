func sort(_ a: inout [Int]) {
    let n = a.count
    guard n > 1 else { return }
    var ordered = true
    for i in 1 ..< n where a[i] < a[i - 1] {
        ordered = false; break
    }
    if ordered {
        return
    }
    func reverse(_ first: Int, _ last: Int) {
        var low = first, high = last
        while low < high {
            a.swapAt(low, high); low += 1; high -= 1
        }
    }
    while true {
        var pivot = n - 2
        while pivot >= 0, a[pivot] >= a[pivot + 1] {
            pivot -= 1
        }
        if pivot < 0 {
            break
        }
        var successor = n - 1
        while a[successor] <= a[pivot] {
            successor -= 1
        }
        a.swapAt(pivot, successor)
        reverse(pivot + 1, n - 1)
    }
    reverse(0, n - 1)
}

var array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
