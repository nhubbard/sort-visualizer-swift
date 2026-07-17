import Foundation

func insertionSort(_ arr: inout [Int]) {
  let n = arr.count
  for i in 1..<n {
    let key = arr[i]
    var j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j -= 1
    }
    arr[j + 1] = key
  }
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  let shrink: Double = 1.3
  var gap = n
  var sorted = false
  let threshold = min(8, n / 32)
  while !sorted {
    gap = Int(floor(Double(gap) / shrink))
    if gap <= 1 {
      sorted = true
      gap = 1
    }
    for i in 0..<(n - gap) {
      if gap <= threshold {
        insertionSort(&arr)
        return
      }
      let sm = gap + i
      if arr[i] > arr[sm] {
        arr.swapAt(i, sm)
        sorted = false
      }
    }
  }
}

var array: [Int] = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
