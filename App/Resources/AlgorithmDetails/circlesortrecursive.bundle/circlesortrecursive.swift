import Foundation

func nextPowerOfTwo(_ n: Int) -> Int {
  var k = 1
  while k < n {
    k <<= 1
  }
  return k
}

func circleSortRoutine(_ array: inout [Int], _ lo: Int, _ hi: Int, _ end: Int) -> Int {
  if lo == hi {
    return 0
  }
  let low = lo
  let high = hi
  let mid = (hi - lo) / 2
  var lo = lo
  var hi = hi
  var swaps = 0
  while lo < hi {
    if hi < end && array[lo] > array[hi] {
      array.swapAt(lo, hi)
      swaps += 1
    }
    lo += 1
    hi -= 1
  }
  swaps += circleSortRoutine(&array, low, low + mid, end)
  if low + mid + 1 < end {
    swaps += circleSortRoutine(&array, low + mid + 1, high, end)
  }
  return swaps
}

func sort(_ array: inout [Int]) {
  let end = array.count
  guard end > 0 else { return }
  let paddedLength = nextPowerOfTwo(end)
  var swaps: Int
  repeat {
    swaps = circleSortRoutine(&array, 0, paddedLength - 1, end)
  } while swaps != 0
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
