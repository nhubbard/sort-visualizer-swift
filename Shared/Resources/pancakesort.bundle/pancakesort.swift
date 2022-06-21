import Foundation

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

var items: [Int] = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
sort(&items)
print(items)
