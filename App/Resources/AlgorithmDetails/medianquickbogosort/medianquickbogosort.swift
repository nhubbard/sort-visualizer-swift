func sortRange(_ arr: inout [Int], _ start: Int, _ end: Int) {
  if start >= end - 1 {
    return
  }
  let mid = (start + end) / 2

  func isSplit() -> Bool {
    var lowMax = arr[start]
    for i in (start + 1)..<mid {
      if arr[i] > lowMax {
        lowMax = arr[i]
      }
    }
    for i in mid..<end {
      if lowMax > arr[i] {
        return false
      }
    }
    return true
  }

  while !isSplit() {
    var sub = Array(arr[start..<end])
    sub.shuffle()
    for i in start..<end {
      arr[i] = sub[i - start]
    }
  }

  sortRange(&arr, start, mid)
  sortRange(&arr, mid, end)
}

func sort(_ arr: inout [Int]) {
  sortRange(&arr, 0, arr.count)
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
