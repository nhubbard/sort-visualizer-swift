import Foundation

func classify(_ value: Int, _ minValue: Int, _ c: Double) -> Int {
  Int(Double(value - minValue) * c) + 1
}

func flashSort(_ array: inout [Int]) {
  let n = array.count
  if n == 0 { return }

  let m = Int(0.2 * Double(n)) + 2

  var minValue = array[0]
  var maxValue = array[0]
  var maxIndex = 0

  var i = 1
  while i < n - 1 {
    let small: Int
    let big: Int
    let bigIndex: Int
    if array[i] < array[i + 1] {
      small = array[i]; big = array[i + 1]; bigIndex = i + 1
    } else {
      big = array[i]; bigIndex = i; small = array[i + 1]
    }
    if big > maxValue { maxValue = big; maxIndex = bigIndex }
    if small < minValue { minValue = small }
    i += 2
  }

  let last = array[n - 1]
  if last < minValue {
    minValue = last
  } else if last > maxValue {
    maxValue = last
    maxIndex = n - 1
  }

  if maxValue == minValue { return }

  var L = [Int](repeating: 0, count: m + 1)
  let c = Double(m - 1) / Double(maxValue - minValue)

  for h in 0..<n {
    let k = classify(array[h], minValue, c)
    L[k] += 1
  }

  for k in 2...m {
    L[k] += L[k - 1]
  }

  array.swapAt(maxIndex, 0)

  var j = 0
  var k = m
  var numMoves = 0
  while numMoves < n {
    while j >= L[k] {
      j += 1
      k = classify(array[j], minValue, c)
    }

    var evicted = array[j]
    while j < L[k] {
      k = classify(evicted, minValue, c)
      let location = L[k] - 1
      let temp = array[location]
      array[location] = evicted
      evicted = temp
      L[k] -= 1
      numMoves += 1
    }
  }

  for idx in 1..<n {
    let current = array[idx]
    var pos = idx - 1
    while pos >= 0 && array[pos] > current {
      array[pos + 1] = array[pos]
      pos -= 1
    }
    array[pos + 1] = current
  }
}

func sort(_ array: inout [Int]) {
  flashSort(&array)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
