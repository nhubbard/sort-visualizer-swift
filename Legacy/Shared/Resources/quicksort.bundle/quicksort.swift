import Foundation

func partition(
  _ array: inout [Int],
  _ begin: Int,
  _ end: Int
) -> Int {
  let pivot = array[end]
  var i = begin - 1
  for j in begin..<end {
    if array[j] <= pivot {
      i += 1
      array.swapAt(i, j)
    }
  }
  array.swapAt(i + 1, end)
  return i + 1
}

func quickSort(_ array: inout [Int], _ begin: Int, _ end: Int) {
  if begin < end {
    let partitionIndex = partition(&array, begin, end)
    quickSort(&array, begin, partitionIndex - 1)
    quickSort(&array, partitionIndex + 1, end)
  }
}

func sort(_ array: inout [Int]) {
  quickSort(&array, 0, array.count - 1)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)