import Foundation

func circleSortRoutine(_ array: inout [Int], _ length: Int, _ end: Int) -> Int {
  var swapCount = 0
  var gap = length / 2
  while gap > 0 {
    var start = 0
    while start + gap < end {
      var low = start
      var high = start + 2 * gap - 1
      while low < high {
        if high < end && array[low] > array[high] {
          array.swapAt(low, high)
          swapCount += 1
        }
        low += 1
        high -= 1
      }
      start += 2 * gap
    }
    gap /= 2
  }
  return swapCount
}

func sort(_ array: inout [Int]) {
  let end = array.count
  if end <= 1 { return }
  var n = 1
  while n < end {
    n <<= 1
  }

  var numberOfSwaps = 1
  while numberOfSwaps != 0 {
    numberOfSwaps = circleSortRoutine(&array, n, end)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
