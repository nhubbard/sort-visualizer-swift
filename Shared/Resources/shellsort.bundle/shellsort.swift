func sort(_ arr: inout [Int]) {
  let n = arr.count
  var i = n / 2
  while i > 0 {
    for j in i..<n {
      var k = j - i
      while k >= 0 {
        if arr[k + i] >= arr[k] {
          break
        } else {
          arr.swapAt(k, k + i)
        }
        k -= i
      }
    }
    i /= 2
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)