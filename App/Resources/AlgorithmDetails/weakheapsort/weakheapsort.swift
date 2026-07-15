func sort(_ arr: inout [Int]) {
  let n = arr.count
  var flags = [Bool](repeating: false, count: n)

  func merge(_ i: Int, _ j: Int) {
    if arr[i] < arr[j] {
      flags[j].toggle()
      arr.swapAt(i, j)
    }
  }

  var i = n - 1
  while i > 0 {
    var j = i
    while (j & 1) == (flags[j >> 1] ? 1 : 0) {
      j >>= 1
    }
    let gparent = j >> 1
    merge(gparent, i)
    i -= 1
  }

  i = n - 1
  while i > 1 {
    arr.swapAt(0, i)
    var x = 1
    while true {
      let y = 2 * x + (flags[x] ? 1 : 0)
      if y >= i {
        break
      }
      x = y
    }
    while x > 0 {
      merge(0, x)
      x >>= 1
    }
    i -= 1
  }
  arr.swapAt(0, 1)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
