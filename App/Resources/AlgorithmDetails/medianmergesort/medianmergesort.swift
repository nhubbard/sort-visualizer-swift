// ArrayV median-merge: the larger partition is an in-array swap buffer.
final class MedianMerge {
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

  private func partition(_ first: Int, _ end: Int, _ pivot: Int) -> Int {
    var i = first - 1
    var j = end
    while true {
      repeat { i += 1 } while i < j && a[i] < a[pivot]
      repeat { j -= 1 } while j >= i && a[j] > a[pivot]
      if i >= j { return j }
      exchange(i, j)
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

  func sort() {
    var first = 0
    var end = a.count
    var badSplit = false
    var usedMedians = false
    while end - first > 16 {
      if badSplit {
        medianMedians(first, end)
        usedMedians = true
      } else { medianThree(first, end) }
      let pivot = partition(first + 1, end, first)
      exchange(first, pivot)
      let left = pivot - first
      let right = end - pivot - 1
      badSplit = !usedMedians &&
        (left == 0 || right == 0 ||
         (left > 0 && right > 0 && (left / right >= 16 || right / left >= 16)))
      if left <= right {
        mergeSort(first, pivot, pivot + 1)
        first = pivot + 1
      } else {
        mergeSort(pivot + 1, end, 2 * pivot + 1 - end)
        end = pivot
      }
    }
    binaryInsertion(first, end)
  }
}

var example = MedianMerge([0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                           68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38])
example.sort()
print(example.a)
