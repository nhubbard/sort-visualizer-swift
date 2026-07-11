func isSorted(_ arr: [Int]) -> Bool {
  for i in 1..<arr.count where arr[i - 1] > arr[i] {
    return false
  }
  return true
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  while !isSorted(arr) {
    let i = Int.random(in: 0..<n)
    let j = Int.random(in: 0..<n)
    if (i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j]) {
      arr.swapAt(i, j)
    }
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23]
sort(&array)
print(array)
