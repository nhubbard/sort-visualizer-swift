import Foundation

func is3Smooth(_ n: Int) -> Bool {
  var n = n
  while n % 6 == 0 { n /= 6 }
  while n % 3 == 0 { n /= 3 }
  while n % 2 == 0 { n /= 2 }
  return n == 1
}

func sort(_ array: inout [Int]) {
  let length = array.count
  var g = length - 1
  while g > 0 {
    if is3Smooth(g) {
      var i = g
      while i < length {
        if array[i - g] > array[i] {
          array.swapAt(i - g, i)
        }
        i += 1
      }
    }
    g -= 1
  }
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
