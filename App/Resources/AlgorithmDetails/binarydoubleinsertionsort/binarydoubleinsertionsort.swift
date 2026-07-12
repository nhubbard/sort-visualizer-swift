import Foundation

func leftBinarySearch(_ array: [Int], _ a: Int, _ b: Int, _ val: Int) -> Int {
  var lo = a
  var hi = b
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if val <= array[mid] {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

func rightBinarySearch(_ array: [Int], _ a: Int, _ b: Int, _ val: Int) -> Int {
  var lo = a
  var hi = b
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if val < array[mid] {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

func insertToLeft(_ array: inout [Int], _ a: Int, _ b: Int, _ temp: Int) {
  var a = a
  while a > b {
    array[a] = array[a - 1]
    a -= 1
  }
  array[b] = temp
}

func insertToRight(_ array: inout [Int], _ a: Int, _ b: Int, _ temp: Int) {
  var a = a
  while a < b {
    array[a] = array[a + 1]
    a += 1
  }
  array[a] = temp
}

func doubleInsertion(_ array: inout [Int], _ a: Int, _ b: Int) {
  if b - a < 2 {
    return
  }

  let j0 = a + (b - a - 2) / 2 + 1
  let i0 = a + (b - a - 1) / 2
  var i = i0
  var j = j0

  if j > i && array[i] > array[j] {
    array.swapAt(i, j)
  }
  i -= 1
  j += 1

  while j < b {
    if array[i] > array[j] {
      let l = array[j]
      let r = array[i]
      let m = rightBinarySearch(array, i + 1, j, l)
      insertToRight(&array, i, m - 1, l)
      let dest = leftBinarySearch(array, m, j, r)
      insertToLeft(&array, j, dest, r)
    } else {
      let l = array[i]
      let r = array[j]
      let m = leftBinarySearch(array, i + 1, j, l)
      insertToRight(&array, i, m - 1, l)
      let dest = rightBinarySearch(array, m, j, r)
      insertToLeft(&array, j, dest, r)
    }
    i -= 1
    j += 1
  }
}

func sort(_ array: inout [Int]) {
  if array.count > 1 {
    doubleInsertion(&array, 0, array.count)
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
