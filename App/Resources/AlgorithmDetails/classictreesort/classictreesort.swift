import Foundation

func traverse(_ arr: [Int], _ temp: inout [Int], _ lower: [Int], _ upper: [Int], _ idx: inout Int, _ r: Int) {
  if lower[r] != 0 {
    traverse(arr, &temp, lower, upper, &idx, lower[r])
  }
  temp[idx] = arr[r]
  idx += 1
  if upper[r] != 0 {
    traverse(arr, &temp, lower, upper, &idx, upper[r])
  }
}

func sort(_ arr: inout [Int]) {
  let n = arr.count
  if n <= 1 {
    return
  }
  var lower = [Int](repeating: 0, count: n)
  var upper = [Int](repeating: 0, count: n)

  for i in 1..<n {
    var c = 0
    while true {
      if arr[i] < arr[c] {
        if lower[c] == 0 {
          lower[c] = i
          break
        } else {
          c = lower[c]
        }
      } else {
        if upper[c] == 0 {
          upper[c] = i
          break
        } else {
          c = upper[c]
        }
      }
    }
  }

  var temp = [Int](repeating: 0, count: n)
  var idx = 0
  traverse(arr, &temp, lower, upper, &idx, 0)
  arr = temp
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
