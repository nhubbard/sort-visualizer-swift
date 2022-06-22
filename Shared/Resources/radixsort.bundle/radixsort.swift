func sort(_ arr: inout [Int]) {
  let n = arr.count
  var bucket = Array(repeating: Array(repeating: 0, count: 10), count: 10)
  var bucketCount = Array(repeating: 0, count: 10)
  var nop = 0
  var divisor = 1
  var lar = arr.max() ?? 0
  while lar > 0 {
    nop += 1
    lar /= 10
  }
  for _ in 0..<nop {
    for i in 0..<10 {
      bucketCount[i] = 0
    }
    for i in 0..<n {
      let r = (arr[i] / divisor) % 10
      bucket[r][bucketCount[r]] = arr[i]
      bucketCount[r] += 1
    }
    var i = 0
    for k in 0..<10 {
      for j in 0..<bucketCount[k] {
        arr[i] = bucket[k][j]
        i += 1
      }
    }
    divisor *= 10
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)