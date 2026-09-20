func sort(_ a: inout [Int]) {
    let n = a.count
    guard n > 1 else { return }
    var swapped = true
    while swapped {
        swapped = false
        for i in 0 ..< (n - 1) where a[i] > a[i + 1] {
            a.swapAt(i, i + 1)
            swapped = true
        }
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
