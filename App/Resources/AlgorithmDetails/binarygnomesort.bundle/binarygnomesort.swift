import Foundation

func binarySearch(
  _ array: [Int],
  _ item: Int,
  _ start: Int,
  _ end: Int
) -> Int {
  var low = start
  var high = end
  while low < high {
    let mid = low + (high - low) / 2
    if item < array[mid] {
      high = mid
    } else {
      low = mid + 1
    }
  }
  return low
}

func binaryGnomeSort(_ array: inout [Int]) {
  for i in 1..<array.count {
    let item = array[i]
    let pos = binarySearch(array, item, 0, i)
    var j = i
    while j > pos {
      array.swapAt(j, j - 1)
      j -= 1
    }
  }
}

func sort(_ array: inout [Int]) {
  binaryGnomeSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
