import Foundation

func sort(_ array: inout [Int]) {
  let n = array.count
  guard n > 0 else {
    return
  }
  let maxValue = array.max()!

  var counts = [Int](repeating: 0, count: maxValue + 1)
  for value in array {
    counts[value] += 1
  }
  for i in 1...maxValue {
    counts[i] += counts[i - 1]
  }

  var output = [Int](repeating: 0, count: n)
  for i in stride(from: n - 1, through: 0, by: -1) {
    counts[array[i]] -= 1
    output[counts[array[i]]] = array[i]
  }

  for i in 0..<n {
    array[i] = output[i]
  }
}

var array: [Int] = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
