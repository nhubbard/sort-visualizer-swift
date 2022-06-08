import Foundation

func shakerSort(_ arr: inout [Int]) {
  let n = arr.count
  var swapped = true
  var start = 0
  var end = n - 1
  while swapped {
    swapped = false
    for i in start..<end {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        swapped = true
      }
    }
    if !swapped {
      break
    }
    swapped = false
    end -= 1
    var i = end - 1
    while i >= start {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        swapped = true
      }
      i -= 1
    }
    start += 1
  }
}

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
shakerSort(&items)
print(items)