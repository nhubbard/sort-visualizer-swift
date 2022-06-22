func sort(_ arr: inout [Int]) {
  let n = arr.count
  var index = 0
  while index < n {
    if index == 0 {
      index += 1
    }
    if arr[index] >= arr[index - 1] {
      index += 1
    } else {
      arr.swapAt(index, index - 1)
      index -= 1
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)