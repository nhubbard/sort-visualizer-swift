import Foundation

func cocktailShakerSort(_ array: inout [Int]) {
  let n = array.count
  var i = 0
  while i < n / 2 {
    var sorted = true
    var j = i
    while j < n - i - 1 {
      if array[j] > array[j + 1] {
        array.swapAt(j, j + 1)
        sorted = false
      }
      j += 1
    }
    j = n - i - 1
    while j > i {
      if array[j] < array[j - 1] {
        array.swapAt(j, j - 1)
        sorted = false
      }
      j -= 1
    }
    if sorted {
      break
    }
    i += 1
  }
}

func sort(_ array: inout [Int]) {
  cocktailShakerSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
