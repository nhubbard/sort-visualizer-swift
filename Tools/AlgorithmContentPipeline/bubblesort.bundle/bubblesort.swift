func sort(_ arr: inout [Int]) {
  let n = arr.count
  for c in 0..<(n - 1) {
    for d in 0..<(n - c - 1) {
      if arr[d] > arr[d + 1] {
        arr.swapAt(d, d + 1)
      }
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)