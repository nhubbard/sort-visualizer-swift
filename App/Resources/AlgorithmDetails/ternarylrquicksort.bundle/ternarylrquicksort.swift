import Foundation

func compare3(_ arr: [Int], _ a: Int, _ b: Int) -> Int {
  if arr[a] == arr[b] { return 0 }
  return arr[a] > arr[b] ? 1 : -1
}

func selectPivot(_ arr: [Int], _ lo: Int, _ hi: Int) -> Int {
  let mid = (lo + hi) / 2
  let cLoMid = compare3(arr, lo, mid)
  if cLoMid == 0 { return lo }
  let cLoHi = compare3(arr, lo, hi - 1)
  let cMidHi = compare3(arr, mid, hi - 1)
  if cLoHi == 0 || cMidHi == 0 { return hi - 1 }

  if cLoMid < 0 {
    return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo)
  } else {
    return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1)
  }
}

func quicksortTernaryLR(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
  if hi <= lo { return }

  let piv = selectPivot(arr, lo, hi + 1)
  arr.swapAt(piv, hi)
  let pivotIndex = hi

  var i = lo
  var j = hi - 1
  var p = lo
  var q = hi - 1

  while true {
    var cmp: Int
    while i <= j {
      cmp = compare3(arr, i, pivotIndex)
      if cmp > 0 { break }
      if cmp == 0 {
        arr.swapAt(i, p)
        p += 1
      }
      i += 1
    }
    while i <= j {
      cmp = compare3(arr, j, pivotIndex)
      if cmp < 0 { break }
      if cmp == 0 {
        arr.swapAt(j, q)
        q -= 1
      }
      j -= 1
    }
    if i > j { break }
    arr.swapAt(i, j)
    i += 1
    j -= 1
  }

  arr.swapAt(i, hi)

  let numLess = i - p
  let numGreater = q - j

  j = i - 1
  i = i + 1

  let pe = lo + min(p - lo, numLess)
  var k = lo
  while k < pe {
    arr.swapAt(k, j)
    k += 1
    j -= 1
  }

  let qe = hi - 1 - min(hi - 1 - q, numGreater - 1)
  k = hi - 1
  while k > qe {
    arr.swapAt(i, k)
    k -= 1
    i += 1
  }

  quicksortTernaryLR(&arr, lo, lo + numLess - 1)
  quicksortTernaryLR(&arr, hi - numGreater + 1, hi)
}

func sort(_ arr: inout [Int]) {
  quicksortTernaryLR(&arr, 0, arr.count - 1)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
