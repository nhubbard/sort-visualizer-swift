import Foundation

func compSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ end: Int) {
  if b >= end { return }
  if array[a] > array[b] {
    array.swapAt(a, b)
  }
}

func rangeComp(_ array: inout [Int], _ a: Int, _ b: Int, _ offset: Int, _ end: Int) {
  let half = (b - a) / 2
  let m = a + half
  let base = a + offset
  var i = 0
  while i < half - offset {
    if (i & ~offset) == i {
      compSwap(&array, base + i, m + i, end)
    }
    i += 1
  }
}

func sort(_ array: inout [Int]) {
  let end = array.count
  if end <= 1 { return }
  var paddedLength = 1
  while paddedLength < end {
    paddedLength <<= 1
  }

  var k = 2
  while k <= paddedLength {
    var j = 0
    while j < k / 2 {
      var i = 0
      while i + j < end {
        rangeComp(&array, i, i + k, j, end)
        i += k
      }
      j += 1
    }
    k *= 2
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
