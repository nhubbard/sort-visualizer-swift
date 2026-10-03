final class OptimizedRotateMergeExample {
  var values: [Int]
  private var buffer = Array(repeating: 0, count: 64)
  init(_ input: [Int]) { values = input }

  private func lowerBound(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var low = start, high = end
    while low < high {
      let middle = low + (high - low) / 2
      if values[middle] < value { low = middle + 1 } else { high = middle }
    }
    return low
  }

  private func upperBound(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var low = start, high = end
    while low < high {
      let middle = low + (high - low) / 2
      if values[middle] <= value { low = middle + 1 } else { high = middle }
    }
    return low
  }

  private func reverse(_ start: Int, _ end: Int) {
    var left = start, right = end - 1
    while left < right { values.swapAt(left, right); left += 1; right -= 1 }
  }

  private func rotate(_ start: Int, _ middle: Int, _ end: Int) {
    guard start < middle && middle < end else { return }
    let left = middle - start, right = end - middle
    if left <= buffer.count {
      for i in 0..<left { buffer[i] = values[start + i] }
      for i in middle..<end { values[i - left] = values[i] }
      for i in 0..<left { values[end - left + i] = buffer[i] }
    } else if right <= buffer.count {
      for i in 0..<right { buffer[i] = values[middle + i] }
      for i in stride(from: middle - 1, through: start, by: -1) { values[i + right] = values[i] }
      for i in 0..<right { values[start + i] = buffer[i] }
    } else {
      reverse(start, middle)
      reverse(middle, end)
      reverse(start, end)
    }
  }

  private func bufferedMerge(_ start: Int, _ middle: Int, _ end: Int) {
    let leftLength = middle - start, rightLength = end - middle
    if leftLength <= rightLength {
      for i in 0..<leftLength { buffer[i] = values[start + i] }
      var left = 0, right = middle, destination = start
      while left < leftLength && right < end {
        if values[right] < buffer[left] { values[destination] = values[right]; right += 1 }
        else { values[destination] = buffer[left]; left += 1 }
        destination += 1
      }
      while left < leftLength { values[destination] = buffer[left]; left += 1; destination += 1 }
    } else {
      for i in 0..<rightLength { buffer[i] = values[middle + i] }
      var left = middle - 1, right = rightLength - 1, destination = end - 1
      while left >= start && right >= 0 {
        if values[left] > buffer[right] { values[destination] = values[left]; left -= 1 }
        else { values[destination] = buffer[right]; right -= 1 }
        destination -= 1
      }
      while right >= 0 { values[destination] = buffer[right]; right -= 1; destination -= 1 }
    }
  }

  private func merge(_ start: Int, _ middle: Int, _ end: Int) {
    guard start < middle && middle < end && values[middle - 1] > values[middle] else { return }
    if min(middle - start, end - middle) <= buffer.count {
      bufferedMerge(start, middle, end)
      return
    }
    let leftSplit: Int, rightSplit: Int
    if middle - start >= end - middle {
      leftSplit = start + (middle - start) / 2
      rightSplit = lowerBound(middle, end, values[leftSplit])
    } else {
      rightSplit = middle + (end - middle) / 2
      leftSplit = upperBound(start, middle, values[rightSplit])
    }
    rotate(leftSplit, middle, rightSplit)
    let newMiddle = leftSplit + rightSplit - middle
    merge(start, leftSplit, newMiddle)
    merge(newMiddle, rightSplit, end)
  }

  private func insertion(_ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for index in (start + 1)..<end {
      let value = values[index]
      let destination = upperBound(start, index, value)
      var cursor = index
      while cursor > destination { values[cursor] = values[cursor - 1]; cursor -= 1 }
      values[destination] = value
    }
  }

  func sort() {
    let count = values.count
    guard count > 1 else { return }
    var start = 0
    while start < count { insertion(start, min(start + 32, count)); start += 32 }
    var run = 32
    while run < count {
      var lower = 0
      while lower + run < count {
        merge(lower, lower + run, min(lower + 2 * run, count))
        lower += 2 * run
      }
      run *= 2
    }
  }
}
var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
let sorter = OptimizedRotateMergeExample(array)
sorter.sort()
array = sorter.values
print(array)
