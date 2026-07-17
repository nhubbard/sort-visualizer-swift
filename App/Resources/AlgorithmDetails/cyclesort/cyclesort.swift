import Foundation

func cycleSort(_ array: inout [Int]) {
  let n = array.count
  guard n > 1 else { return }

  for cycleStart in 0..<(n - 1) {
    var item = array[cycleStart]
    var pos = cycleStart
    for i in (cycleStart + 1)..<n where array[i] < item {
      pos += 1
    }
    if pos == cycleStart { continue }

    while item == array[pos] {
      pos += 1
    }
    (item, array[pos]) = (array[pos], item)

    while pos != cycleStart {
      pos = cycleStart
      for i in (cycleStart + 1)..<n where array[i] < item {
        pos += 1
      }
      while item == array[pos] {
        pos += 1
      }
      (item, array[pos]) = (array[pos], item)
    }
  }
}

func sort(_ array: inout [Int]) {
  cycleSort(&array)
}

var array: [Int] = [
  0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
