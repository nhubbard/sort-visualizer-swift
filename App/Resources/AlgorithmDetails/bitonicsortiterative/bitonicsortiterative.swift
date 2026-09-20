func sort(_ arr: inout [Int]) {
    let n = arr.count
    var k = 2
    while k < 2 * n {
        let m = ((n + k - 1) / k) % 2 != 0
        var j = k / 2
        while j > 0 {
            var i = 0
            while i < n {
                let l = i ^ j
                if l > i && l < n {
                    let ascending = ((i & k) == 0) == m
                    if (ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l]) {
                        arr.swapAt(i, l)
                    }
                }
                i += 1
            }
            j /= 2
        }
        k *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
