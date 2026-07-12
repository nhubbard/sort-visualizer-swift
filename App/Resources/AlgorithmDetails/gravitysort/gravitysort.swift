import Foundation

func gravitySort(_ arr: inout [Int]) {
  let n = arr.count
  guard n > 0 else { return }

  let minValue = arr.min()!
  let maxValue = arr.max()!
  let ySize = maxValue - minValue + 1

  var x = [Int](repeating: 0, count: n)
  var y = [Int](repeating: 0, count: ySize)

  for i in 0..<n {
    x[i] = arr[i] - minValue
    y[x[i]] += 1
  }

  for i in stride(from: ySize - 1, to: 0, by: -1) {
    y[i - 1] += y[i]
  }

  for j in stride(from: ySize - 1, through: 0, by: -1) {
    for i in 0..<n {
      let inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0)
      arr[i] += inc
    }
  }
}

func sort(_ arr: inout [Int]) {
  gravitySort(&arr)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
