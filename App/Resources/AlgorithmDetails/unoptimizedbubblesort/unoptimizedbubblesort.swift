import Foundation

func sort(_ array: inout [Int]) {
  var sorted = false
  while !sorted {
    sorted = true
    for i in 0..<(array.count - 1) where array[i] > array[i + 1] {
      array.swapAt(i, i + 1)
      sorted = false
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
