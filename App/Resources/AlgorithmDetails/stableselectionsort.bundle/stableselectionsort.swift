import Foundation

func sort(_ array: inout [Int]) {
  for i in 0..<(array.count - 1) {
    var min = i
    for j in (i + 1)..<array.count {
      if array[j] < array[min] {
        min = j
      }
    }
    let tmp = array[min]
    var pos = min
    while pos > i {
      array[pos] = array[pos - 1]
      pos -= 1
    }
    array[pos] = tmp
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
