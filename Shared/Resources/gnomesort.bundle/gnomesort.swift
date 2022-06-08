func gnomeSort(_ arr: inout [Int]) {
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

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
gnomeSort(&items)
print(items)