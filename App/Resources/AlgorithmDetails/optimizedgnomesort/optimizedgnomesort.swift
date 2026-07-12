import Foundation

func sort(_ array: inout [Int]) {
  let n = array.count
  for i in 1..<n {
    var pos = i
    while pos > 0 && array[pos - 1] > array[pos] {
      array.swapAt(pos - 1, pos)
      pos -= 1
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
