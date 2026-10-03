// ArrayV median-merge: the larger partition is an in-array swap buffer.
final class BufferPartitionMerge {
  var a: [Int]
  init(_ values: [Int]) { a = values }

  private func exchange(_ i: Int, _ j: Int) { a.swapAt(i, j) }

  private func insertion(_ first: Int, _ end: Int) {
    guard end - first > 1 else { return }
    for i in (first + 1)..<end {
      var j = i
      while j > first && a[j - 1] > a[j] {
        exchange(j - 1, j)
        j -= 1
      }
    }
  }

  private func binaryInsertion(_ first: Int, _ end: Int) {
    guard end - first > 1 else { return }
    for i in (first + 1)..<end {
      let value = a[i]
      var low = first
      var high = i
      while low < high {
        let middle = low + (high - low) / 2
        if value < a[middle] { high = middle }
        else { low = middle + 1 }
      }
      var j = i
      while j > low {
        a[j] = a[j - 1]
        j -= 1
      }
      a[low] = value
    }
  }

  private func medianThree(_ first: Int, _ end: Int) {
    let middle = first + (end - 1 - first) / 2
    if a[first] > a[middle] { exchange(first, middle) }
    if a[middle] > a[end - 1] {
      exchange(middle, end - 1)
      if a[first] > a[middle] { return }
    }
    exchange(first, middle)
  }

  private func medianMedians(_ first: Int, _ initialEnd: Int) {
    var end = initialEnd
    var alternate = true
    while end - first > 1 {
      var write = first
      var i = first
      while i + 10 <= end {
        insertion(i, i + 5)
        exchange(write, i + 2)
        write += 1
        i += 5
      }
      if i < end {
        insertion(i, end)
        exchange(write, i + (end - (alternate ? 1 : 0) - i) / 2)
        write += 1
        if (end - i) % 2 == 0 { alternate.toggle() }
      }
      end = write
    }
  }

  private func shiftBackward(_ first: Int, _ middleStart: Int, _ endStart: Int) {
    var middle = middleStart
    var end = endStart
    while middle > first { middle -= 1; end -= 1; exchange(middle, end) }
  }
  private func multiSwap(_ first: Int, _ second: Int, _ length: Int) {
    for offset in 0..<length { exchange(first + offset, second + offset) }
  }
  private func rotate(_ firstStart: Int, _ middleStart: Int, _ endStart: Int) {
    var first = firstStart
    var middle = middleStart
    var end = endStart
    var left = middle - first
    var right = end - middle
    while left > 0 && right > 0 {
      if right < left {
        multiSwap(middle - right, middle, right)
        end -= right; middle -= right; left -= right
      } else {
        multiSwap(first, middle, left)
        first += left; middle += left; right -= left
      }
    }
  }
  private func inPlaceMerge(_ first: Int, _ middleStart: Int, _ end: Int) {
    var left = first
    var right = middleStart
    while left < right && right < end {
      if a[left] > a[right] {
        var upper = right + 1
        while upper < end && a[left] > a[upper] { upper += 1 }
        rotate(left, right, upper)
        left += upper - right
        right = upper
      } else { left += 1 }
    }
  }
  private func partition(_ first: Int, _ end: Int) -> Int {
    var left = first
    var right = end
    while true {
      repeat { left += 1 } while left < right && a[left] > a[first]
      repeat { right -= 1 } while right >= left && a[right] < a[first]
      if left >= right { return right }
      exchange(left, right)
    }
  }
  private func quickSelect(_ lowerStart: Int, _ upperStart: Int, _ target: Int) -> Int {
    var lower = lowerStart
    var upper = upperStart
    var badSplit = false
    var usedMedians = false
    let targetUpper = (target + upper + 1) / 2
    while true {
      if badSplit { medianMedians(lower, upper); usedMedians = true }
      else { medianThree(lower, upper) }
      let pivot = partition(lower, upper)
      exchange(lower, pivot)
      let left = max(1, pivot - lower)
      let right = max(1, upper - pivot - 1)
      badSplit = !usedMedians && (left / right >= 16 || right / left >= 16)
      if pivot >= target && pivot < targetUpper { return pivot }
      if pivot < target { lower = pivot + 1 }
      else { upper = pivot }
    }
  }
  private func merge(_ first: Int, _ middle: Int, _ end: Int, _ destinationStart: Int) {
    var i = first
    var j = middle
    var destination = destinationStart
    while i < middle && j < end {
      if a[i] <= a[j] {
        exchange(destination, i)
        i += 1
      } else {
        exchange(destination, j)
        j += 1
      }
      destination += 1
    }
    while i < middle { exchange(destination, i); destination += 1; i += 1 }
    while j < end { exchange(destination, j); destination += 1; j += 1 }
  }

  private func mergeSort(_ first: Int, _ end: Int, _ buffer: Int) {
    let length = end - first
    guard length > 1 else { return }
    var width = length
    while width >= 32 { width = (width + 3) / 4 }
    var i = first
    while i + width <= end {
      binaryInsertion(i, i + width)
      i += width
    }
    binaryInsertion(i, end)
    while width < length {
      var destination = buffer
      i = first
      while i + 2 * width <= end {
        merge(i, i + width, i + 2 * width, destination)
        i += 2 * width
        destination += 2 * width
      }
      if i + width < end { merge(i, i + width, end, destination) }
      else {
        while i < end { exchange(i, destination); i += 1; destination += 1 }
      }
      width *= 2

      destination = first
      i = buffer
      while i + 2 * width <= buffer + length {
        merge(i, i + width, i + 2 * width, destination)
        i += 2 * width
        destination += 2 * width
      }
      if i + width < buffer + length {
        merge(i, i + width, buffer + length, destination)
      } else {
        while i < buffer + length { exchange(i, destination); i += 1; destination += 1 }
      }
      width *= 2
    }
  }

  private func mergeForward(_ destinationStart: Int, _ first: Int, _ middle: Int, _ end: Int) -> Int {
    var destination = destinationStart
    var left = first
    var right = middle
    while left < middle && right < end {
      if a[left] <= a[right] { exchange(destination, left); left += 1 }
      else { exchange(destination, right); right += 1 }
      destination += 1
    }
    return left < middle ? left : right
  }
  func sort() {
    let n = a.count
    guard n > 1 else { return }
    var first = 0
    var middle = (n + 1) / 2
    let minimum = Int(Double(n).squareRoot())
    mergeSort(middle, n, first)
    while middle - first > minimum {
      var selected = quickSelect(first, middle, (first + middle + 1) / 2)
      mergeSort(selected, middle, first)
      let bufferLength = selected - first
      var mergeEnd = min(selected + bufferLength, n)
      selected = mergeForward(first, selected, middle, mergeEnd)
      while selected < middle {
        shiftBackward(selected, middle, mergeEnd)
        selected = mergeEnd - (middle - selected)
        first = selected - bufferLength
        middle = mergeEnd
        if middle == n { break }
        mergeEnd = min(mergeEnd + bufferLength, n)
        selected = mergeForward(first, selected, middle, mergeEnd)
      }
      middle = selected
      first = selected - bufferLength
    }
    binaryInsertion(first, middle)
    inPlaceMerge(first, middle, n)
  }
}

var example = BufferPartitionMerge([0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56])
example.sort()
print(example.a)
