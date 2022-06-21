import Foundation

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

// Specific to bitonic sort: size must be power of 2.
var items: [Int] = [35, 74, 71, 72, 30, 53, 9, 0]
sort(&items)
print(items)
