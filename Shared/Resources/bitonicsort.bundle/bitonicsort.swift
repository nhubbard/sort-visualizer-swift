func sort(_ arr: inout [Int]) {
  let n = arr.count
  var k = 2
  while k <= n {
    var j = k / 2
    while j > 0 {
      var i = 0
      while i < n {
        let l = i ^ j
        if l > i {
          if (((i & k) == 0) && (arr[i] > arr[l]) ||
             (((i & k) != 0) && (arr[i] < arr[l]))) {
            arr.swapAt(i, l)
          }
        }
        i += 1
      }
      j /= 2
    }
    k *= 2
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)