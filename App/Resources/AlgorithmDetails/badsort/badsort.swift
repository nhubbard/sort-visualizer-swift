import Foundation

func sort(_ array: inout [Int]) {
  let currentLen = array.count
  for i in 0..<currentLen {
    var shortest = i

    var j = i
    while j < currentLen {
      var isShortest = true
      var k = j + 1
      while k < currentLen {
        if array[j] > array[k] {
          isShortest = false
          break
        }
        k += 1
      }
      if isShortest {
        shortest = j
        break
      }
      j += 1
    }

    array.swapAt(i, shortest)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
