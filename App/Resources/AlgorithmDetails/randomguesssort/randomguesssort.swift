func sort(_ arr: inout [Int]) {
  let n = arr.count
  var loops = [Int](repeating: 0, count: n)
  while true {
    var isSorted = true
    for i in 0..<(n - 1) {
      let a = arr[loops[i]]
      let b = arr[loops[i + 1]]
      if a < b || (a == b && loops[i] < loops[i + 1]) {
        continue
      }
      isSorted = false
      break
    }
    if isSorted {
      break
    }
    for pos in 0..<n {
      loops[pos] = Int.random(in: 0..<n)
    }
  }

  let mapped = loops.map { arr[$0] }
  for i in 0..<n {
    arr[i] = mapped[i]
  }
}

var array: [Int] = [0, 39, 21, 62, 14]
sort(&array)
print(array)
