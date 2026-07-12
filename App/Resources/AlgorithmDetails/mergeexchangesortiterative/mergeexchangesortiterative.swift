import Foundation

func mergeExchangeSort(_ array: inout [Int]) {
  let n = array.count
  guard n > 1 else { return }
  let t = Int(log(Double(n - 1)) / log(2.0)) + 1
  let p0 = 1 << (t - 1)
  var p = p0
  while p > 0 {
    var q = p0
    var r = 0
    var d = p
    while true {
      if n - d > 0 {
        for i in 0..<(n - d) {
          if (i & p) == r && array[i] > array[i + d] {
            array.swapAt(i, i + d)
          }
        }
      }
      if q == p { break }
      d = q - p
      q >>= 1
      r = p
    }
    p >>= 1
  }
}

func sort(_ array: inout [Int]) {
  mergeExchangeSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
