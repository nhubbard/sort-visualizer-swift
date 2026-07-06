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

func partitionTernaryLL(_ arr: inout [Int], _ lo: Int, _ hi: Int) -> (first: Int, second: Int) {
  let p = selectPivot(arr, lo, hi)
  arr.swapAt(p, hi - 1)
  let pivotIndex = hi - 1

  var i = lo
  var k = hi - 1

  var j = lo
  while j < k {
    let cmp = compare3(arr, j, pivotIndex)
    if cmp == 0 {
      k -= 1
      arr.swapAt(k, j)
      j -= 1
    } else if cmp < 0 {
      arr.swapAt(i, j)
      i += 1
    }
    j += 1
  }

  for s in 0..<(hi - k) {
    arr.swapAt(i + s, hi - 1 - s)
  }

  return (i, i + (hi - k))
}

func quicksortTernaryLL(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
  if lo + 1 < hi {
    let mid = partitionTernaryLL(&arr, lo, hi)
    quicksortTernaryLL(&arr, lo, mid.first)
    quicksortTernaryLL(&arr, mid.second, hi)
  }
}

func sort(_ arr: inout [Int]) {
  quicksortTernaryLL(&arr, 0, arr.count)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
