func flip(_ arr: inout [Int], _ k: Int) {
  var n = k
  var left = 0
  while left < n {
    arr.swapAt(left, n)
    n -= 1
    left += 1
  }
}

func maxIndex(_ arr: inout [Int], _ n: Int) -> Int {
  var index = 0
  for i in 0..<n {
    if arr[i] > arr[index] {
      index = i
    }
  }
  return index
}

func sort(_ arr: inout [Int]) {
  var n = arr.count
  while n > 1 {
    let max = maxIndex(&arr, n)
    if max != n {
      flip(&arr, max)
      flip(&arr, n - 1)
    }
    n -= 1
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)