func sort(_ arr: inout [Int]) {
  let n = arr.count
  for i in 0..<(n - 1) {
    var minIdx = i
    for j in (i + 1)..<n {
      if arr[j] < arr[minIdx] {
        minIdx = j
      }
    }
    arr.swapAt(minIdx, i)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)