func sort(_ arr: inout [Int]) {
  let n = arr.count
  var sorted = false
  while !sorted {
    sorted = true
    for i in stride(from: 1, to: n - 1, by: 2) {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        sorted = false
      }
    }
    for i in stride(from: 0, to: n - 1, by: 2) {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        sorted = false
      }
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)