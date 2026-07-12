import Foundation

func sort(_ array: inout [Int]) {
  let n = array.count
  var start = 0
  var end = n - 1
  while start < end {
    var consecSorted = 1
    var i = start
    while i < end {
      if array[i] > array[i + 1] {
        array.swapAt(i, i + 1)
        consecSorted = 1
      } else {
        consecSorted += 1
      }
      i += 1
    }
    end -= consecSorted

    consecSorted = 1
    var j = end
    while j > start {
      if array[j - 1] > array[j] {
        array.swapAt(j - 1, j)
        consecSorted = 1
      } else {
        consecSorted += 1
      }
      j -= 1
    }
    start += consecSorted
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
