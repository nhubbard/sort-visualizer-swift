func sort(_ arr: inout [Int]) {
    let n = arr.count
    for i in 0 ..< n {
        while arr[i] != arr[i...].min()! {
            let j = Int.random(in: i ... (n - 1))
            arr.swapAt(i, j)
        }
    }
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
