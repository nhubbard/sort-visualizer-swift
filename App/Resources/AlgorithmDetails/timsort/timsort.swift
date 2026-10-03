// Copyright (C) 2008 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

final class TimSortExample {
  var values: [Int]
  private let count: Int
  private let stackCapacity: Int
  private var runBase: [Int]
  private var runLength: [Int]
  private var stackSize = 0
  private var temp: [Int] = []
  private var minGallop = 7

  init(_ input: [Int]) {
    values = input
    count = input.count
    stackCapacity = count < 120 ? 5 : count < 1542 ? 10 : count < 119_151 ? 19 : 40
    runBase = Array(repeating: 0, count: stackCapacity)
    runLength = Array(repeating: 0, count: stackCapacity)
  }

  private func reverseRun(_ first: Int, _ last: Int) {
    var left = first, right = last
    while left < right { values.swapAt(left, right); left += 1; right -= 1 }
  }

  private func base(_ index: Int) -> Int {
    return runBase[index]
  }

  private func length(_ index: Int) -> Int {
    return runLength[index]
  }

  private func setBase(_ index: Int, _ value: Int) {
    runBase[index] = value
  }

  private func setLength(_ index: Int, _ value: Int) {
    runLength[index] = value
  }

  private func save(_ index: Int, _ value: Int) {
    temp[index] = value
  }

  private func load(_ index: Int) -> Int {
    return temp[index]
  }

  private func ensureCapacity(_ minimum: Int) {
    guard temp.count < minimum else { return }
    var capacity = max(1, temp.count)
    while capacity < minimum { capacity *= 2 }
    capacity = min(capacity, max(1, count / 2))
    temp = Array(repeating: 0, count: capacity)
  }

  private func minRunLength(_ value: Int) -> Int {
    var n = value
    var remainder = 0
    while n >= 32 {
      remainder |= n & 1
      n >>= 1
    }
    return n + remainder
  }

  private func countRun(_ start: Int, _ end: Int) -> Int {
    guard start + 1 < end else { return 1 }
    var cursor = start + 2
    if (values[start + 1] < values[start]) {
      while cursor < end && (values[cursor] < values[cursor - 1]) { cursor += 1 }
      reverseRun(start, cursor - 1)
    } else {
      while cursor < end && (values[cursor] >= values[cursor - 1]) { cursor += 1 }
    }
    return cursor - start
  }

  private func binaryInsertion(_ start: Int, _ end: Int, _ sortedEnd: Int) {
    var cursor = max(start + 1, sortedEnd)
    while cursor < end {
      let pivot = values[cursor]
      var low = start
      var high = cursor
      while low < high {
        let middle = low + (high - low) / 2
        if (values[middle] <= pivot) { low = middle + 1 }
        else { high = middle }
      }
      var shift = cursor
      while shift > low {
        values[shift] = values[shift - 1]
        shift -= 1
      }
      values[low] = pivot
      cursor += 1
    }
  }

  private func pushRun(_ start: Int, _ runLength: Int) {
    setBase(stackSize, start)
    setLength(stackSize, runLength)
    stackSize += 1
  }

  private func collapse() {
    while stackSize > 1 {
      var index = stackSize - 2
      if (index >= 1 && length(index - 1) <= length(index) + length(index + 1)) ||
        (index >= 2 && length(index - 2) <= length(index) + length(index - 1)) {
        if length(index - 1) < length(index + 1) { index -= 1 }
      } else if length(index) > length(index + 1) {
        break
      }
      mergeAt(index)
    }
  }

  private func forceCollapse() {
    while stackSize > 1 {
      var index = stackSize - 2
      if index > 0 && length(index - 1) < length(index + 1) { index -= 1 }
      mergeAt(index)
    }
  }

  /// Exponential search from either end, followed by binary search in the bracket. `upper`
  /// places equal keys after the searched run; `lower` places them before it.
  private func gallop(
    _ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool,
    valueAt: (Int) -> Int
  ) -> Int {
    guard start < end else { return start }
    func beforeInsertion(_ index: Int) -> Bool {
      let value = valueAt(index)
      return upper ? value <= key : value < key
    }
    var low: Int
    var high: Int
    if fromEnd {
      high = end
      low = end - 1
      var step = 1
      while !beforeInsertion(low) {
        high = low
        if low == start { break }
        step = min(end - start, step * 2)
        low = max(start, end - step)
      }
    } else {
      low = start
      high = start + 1
      while beforeInsertion(high - 1) && high < end {
        low = high
        high = min(end, start + (high - start) * 2)
      }
    }
    while low < high {
      let middle = low + (high - low) / 2
      if beforeInsertion(middle) { low = middle + 1 }
      else { high = middle }
    }
    return low
  }

  private func mainGallop(_ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool = false) -> Int {
    gallop(start, end, key, upper: upper, fromEnd: fromEnd) { values[$0] }
  }

  private func tempGallop(_ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool = false) -> Int {
    gallop(start, end, key, upper: upper, fromEnd: fromEnd) { load($0) }
  }

  private func mergeAt(_ index: Int) {
    var leftStart = base(index)
    var leftLength = length(index)
    let rightStart = base(index + 1)
    var rightLength = length(index + 1)
    setLength(index, leftLength + rightLength)
    if index == stackSize - 3 {
      setBase(index + 1, base(index + 2))
      setLength(index + 1, length(index + 2))
    }
    stackSize -= 1

    let firstRight = values[rightStart]
    let skippedLeft = mainGallop(leftStart, rightStart, firstRight, upper: true)
    leftLength -= skippedLeft - leftStart
    leftStart = skippedLeft
    if leftLength == 0 { return }

    let lastLeft = values[rightStart - 1]
    rightLength = mainGallop(rightStart, rightStart + rightLength, lastLeft, upper: false) - rightStart
    if rightLength == 0 { return }

    if leftLength <= rightLength { mergeLow(leftStart, leftLength, rightStart, rightLength) }
    else { mergeHigh(leftStart, leftLength, rightStart, rightLength) }
  }

  private func mergeLow(_ leftStart: Int, _ leftLength: Int, _ rightStart: Int, _ rightLength: Int) {
    ensureCapacity(leftLength)
    for offset in 0..<leftLength { save(offset, values[leftStart + offset]) }
    var left = 0
    var right = rightStart
    var destination = leftStart
    let rightEnd = rightStart + rightLength
    var leftWins = 0
    var rightWins = 0
    var galloped = false
    while left < leftLength && right < rightEnd {
      if (values[right] < load(left)) {
        values[destination] = values[right]
        right += 1
        rightWins += 1
        leftWins = 0
      } else {
        values[destination] = load(left)
        left += 1
        leftWins += 1
        rightWins = 0
      }
      destination += 1
      if left >= leftLength || right >= rightEnd { break }
      if max(leftWins, rightWins) < minGallop { continue }
      galloped = true

      let leftStop = tempGallop(left, leftLength, values[right], upper: true)
      while left < leftStop {
        values[destination] = load(left)
        left += 1
        destination += 1
      }
      if left == leftLength { break }
      values[destination] = values[right]
      right += 1
      destination += 1
      if right == rightEnd { break }

      let rightStop = mainGallop(right, rightEnd, load(left), upper: false)
      while right < rightStop {
        values[destination] = values[right]
        right += 1
        destination += 1
      }
      if right == rightEnd { break }
      values[destination] = load(left)
      left += 1
      destination += 1
      minGallop = max(1, minGallop - 1)
      leftWins = 0
      rightWins = 0
    }
    while left < leftLength {
      values[destination] = load(left)
      left += 1
      destination += 1
    }
    if galloped { minGallop += 2 }
  }

  private func mergeHigh(_ leftStart: Int, _ leftLength: Int, _ rightStart: Int, _ rightLength: Int) {
    ensureCapacity(rightLength)
    for offset in 0..<rightLength { save(offset, values[rightStart + offset]) }
    var left = rightStart - 1
    var right = rightLength - 1
    var destination = rightStart + rightLength - 1
    var leftWins = 0
    var rightWins = 0
    var galloped = false
    while left >= leftStart && right >= 0 {
      if (load(right) < values[left]) {
        values[destination] = values[left]
        left -= 1
        leftWins += 1
        rightWins = 0
      } else {
        values[destination] = load(right)
        right -= 1
        rightWins += 1
        leftWins = 0
      }
      destination -= 1
      if left < leftStart || right < 0 { break }
      if max(leftWins, rightWins) < minGallop { continue }
      galloped = true

      let leftStop = mainGallop(leftStart, left + 1, load(right), upper: true, fromEnd: true)
      while left >= leftStop {
        values[destination] = values[left]
        left -= 1
        destination -= 1
      }
      if left < leftStart { break }
      values[destination] = load(right)
      right -= 1
      destination -= 1
      if right < 0 { break }

      let rightStop = tempGallop(0, right + 1, values[left], upper: false, fromEnd: true)
      while right >= rightStop {
        values[destination] = load(right)
        right -= 1
        destination -= 1
      }
      if right < 0 { break }
      values[destination] = values[left]
      left -= 1
      destination -= 1
      minGallop = max(1, minGallop - 1)
      leftWins = 0
      rightWins = 0
    }
    while right >= 0 {
      values[destination] = load(right)
      right -= 1
      destination -= 1
    }
    if galloped { minGallop += 2 }
  }

  func sort() {
    if count < 32 {
      let run = countRun(0, count)
      binaryInsertion(0, count, run)
      return
    }
    let minRun = minRunLength(count)
    var cursor = 0
    while cursor < count {
      var run = countRun(cursor, count)
      if run < minRun {
        let forced = min(minRun, count - cursor)
        binaryInsertion(cursor, cursor + forced, cursor + run)
        run = forced
      }
      pushRun(cursor, run)
      collapse()
      cursor += run
    }
    forceCollapse()
  }
}

var example = TimSortExample([0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                              68, 83, 32, 56])
example.sort()
print(example.values)
