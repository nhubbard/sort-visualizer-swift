func sort(_ arr: inout [Int]) {
  let n = arr.count

  func isSorted() -> Bool {
    for i in 0..<n - 1 {
      if arr[i] > arr[i + 1] {
        return false
      }
    }
    return true
  }

  func permutationSort(_ depth: Int) -> Bool {
    if depth >= n - 1 {
      return isSorted()
    }
    for i in stride(from: n - 1, through: depth + 1, by: -1) {
      if permutationSort(depth + 1) {
        return true
      }
      if (n - depth) % 2 == 0 {
        arr.swapAt(depth, i)
      } else {
        arr.swapAt(depth, n - 1)
      }
    }
    return permutationSort(depth + 1)
  }

  permutationSort(0)
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
