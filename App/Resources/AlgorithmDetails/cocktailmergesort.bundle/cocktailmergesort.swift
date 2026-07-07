import Foundation

func minRunLength(_ length: Int) -> Int {
  var n = length
  var r = 0
  while n >= 64 {
    r |= n & 1
    n >>= 1
  }
  return n + r
}

func cocktailShakerSort(_ array: inout [Int], _ start: Int, _ end: Int) {
  let length = end - start
  if length <= 1 {
    return
  }
  var i = 0
  while i < length / 2 {
    var isSorted = true
    var j = i
    while j < length - i - 1 {
      if array[start + j] > array[start + j + 1] {
        array.swapAt(start + j, start + j + 1)
        isSorted = false
      }
      j += 1
    }
    j = length - i - 1
    while j > i {
      if array[start + j - 1] > array[start + j] {
        array.swapAt(start + j - 1, start + j)
        isSorted = false
      }
      j -= 1
    }
    if isSorted {
      break
    }
    i += 1
  }
}

func merge(_ array: inout [Int], _ start: Int, _ mid: Int, _ end: Int) {
  let left = Array(array[start..<mid])
  let right = Array(array[mid..<end])
  var i = 0
  var j = 0
  var k = start
  while i < left.count && j < right.count {
    if left[i] <= right[j] {
      array[k] = left[i]
      i += 1
    } else {
      array[k] = right[j]
      j += 1
    }
    k += 1
  }
  while i < left.count {
    array[k] = left[i]
    i += 1
    k += 1
  }
  while j < right.count {
    array[k] = right[j]
    j += 1
    k += 1
  }
}

func cocktailMergeSort(_ array: inout [Int]) {
  let n = array.count
  if n <= 1 {
    return
  }
  let minRun = minRunLength(n)
  if n == minRun {
    cocktailShakerSort(&array, 0, n)
    return
  }
  var i = 0
  while i <= n - minRun {
    cocktailShakerSort(&array, i, i + minRun)
    i += minRun
  }
  if i < n {
    cocktailShakerSort(&array, i, n)
  }
  var width = minRun
  while width < n {
    i = 0
    while i < n {
      let mid = min(i + width, n)
      let end = min(i + 2 * width, n)
      if mid < end {
        merge(&array, i, mid, end)
      }
      i += 2 * width
    }
    width *= 2
  }
}

func sort(_ array: inout [Int]) {
  cocktailMergeSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
