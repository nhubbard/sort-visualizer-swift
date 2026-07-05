func sort(_ arr: inout [Int]) {
  let n = arr.count
  var swapped = true
  var start = 0
  var end = n - 1
  while swapped {
    swapped = false
    for i in start..<end {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        swapped = true
      }
    }
    if !swapped {
      break
    }
    swapped = false
    end -= 1
    var i = end - 1
    while i >= start {
      if arr[i] > arr[i + 1] {
        arr.swapAt(i, i + 1)
        swapped = true
      }
      i -= 1
    }
    start += 1
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)