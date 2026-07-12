import Foundation

func destination(_ array: [Int], _ flagged: [Bool], _ a: Int, _ b1: Int, _ b: Int) -> Int {
  let heldValue = array[a]
  var d = a
  var e = 0
  for i in (a + 1)..<b {
    if array[i] < heldValue {
      d += 1
    } else if i < b1 && !flagged[i] && array[i] == heldValue {
      e += 1
    }
  }
  while flagged[d] || e > 0 {
    if !flagged[d] {
      e -= 1
    }
    d += 1
  }
  return d
}

func stableCycleSort(_ array: inout [Int]) {
  let n = array.count
  guard n > 1 else { return }
  var flagged = [Bool](repeating: false, count: n)
  for i in 0..<(n - 1) {
    if flagged[i] { continue }
    var j = i
    repeat {
      let k = destination(array, flagged, i, j, n)
      array.swapAt(i, k)
      flagged[k] = true
      j = k
    } while j != i
  }
}

func sort(_ array: inout [Int]) {
  stableCycleSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
