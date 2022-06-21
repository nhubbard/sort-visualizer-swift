import Foundation

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

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
sort(&items)
print(items)
