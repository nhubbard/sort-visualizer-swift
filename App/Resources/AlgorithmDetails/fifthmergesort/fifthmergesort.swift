// Five-way stable merge with a one-fifth external buffer.
final class FifthMerge {
  var a: [Int]
  private let n: Int
  private let chunk: Int
  private let bufferLength: Int
  private var buffer: [Int]

  init(_ values: [Int]) {
    a = values
    n = values.count
    chunk = n / 5
    bufferLength = n - 4 * chunk
    buffer = Array(repeating: 0, count: bufferLength)
  }

  private func binaryInsertion(_ first: Int, _ end: Int) {
    guard end - first > 1 else { return }
    for i in (first + 1)..<end {
      let value = a[i]
      var low = first
      var high = i
      while low < high {
        let middle = low + (high - low) / 2
        if a[middle] > value { high = middle }
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

  private func source(_ index: Int, _ offset: Int, _ fromBuffer: Bool) -> Int {
    fromBuffer ? buffer[index - offset] : a[index]
  }

  private func merge(_ offset: Int, _ first: Int, _ middle: Int, _ end: Int,
                     _ fromBuffer: Bool) {
    var left = first
    var right = middle
    var destination = fromBuffer ? first : first - offset
    func write(_ value: Int) {
      if fromBuffer { a[destination] = value }
      else { buffer[destination] = value }
      destination += 1
    }
    while left < middle && right < end {
      if source(left, offset, fromBuffer) <= source(right, offset, fromBuffer) {
        write(source(left, offset, fromBuffer))
        left += 1
      } else {
        write(source(right, offset, fromBuffer))
        right += 1
      }
    }
    while left < middle { write(source(left, offset, fromBuffer)); left += 1 }
    while right < end { write(source(right, offset, fromBuffer)); right += 1 }
  }

  private func pingPong(_ first: Int, _ end: Int) {
    var i = first
    while i + 8 < end {
      binaryInsertion(i, i + 8)
      i += 8
    }
    if end - i > 1 { binaryInsertion(i, end) }
    let length = end - first
    var fromBuffer = false
    var gap = 8
    while gap < length {
      let full = gap * 2
      i = first
      while i + full < end {
        merge(first, i, i + gap, i + full, fromBuffer)
        i += full
      }
      if i + gap < end { merge(first, i, i + gap, end, fromBuffer) }
      else {
        for j in i..<end {
          if fromBuffer { a[j] = buffer[j - first] }
          else { buffer[j - first] = a[j] }
        }
      }
      fromBuffer.toggle()
      gap *= 2
    }
    if fromBuffer {
      for j in 0..<length { a[first + j] = buffer[j] }
    }
  }

  private func mergeForward(_ destinationStart: Int, _ first: Int, _ middle: Int, _ end: Int) {
    var destination = destinationStart
    var left = first
    var right = middle
    while left < middle && right < end {
      if a[left] <= a[right] { a[destination] = a[left]; left += 1 }
      else { a[destination] = a[right]; right += 1 }
      destination += 1
    }
    while left < middle { a[destination] = a[left]; destination += 1; left += 1 }
    while right < end { a[destination] = a[right]; destination += 1; right += 1 }
  }

  private func mergeBackward(_ destinationStart: Int, _ middle: Int, _ end: Int) -> (Int, Int) {
    var destination = destinationStart
    var left = middle - 1
    var right = end - 1
    while destination > right && right >= middle && left >= 0 {
      if a[left] > a[right] { a[destination] = a[left]; left -= 1 }
      else { a[destination] = a[right]; right -= 1 }
      destination -= 1
    }
    if left < 0 {
      while right >= middle { a[destination] = a[right]; destination -= 1; right -= 1 }
    } else if right == left {
      while right >= 0 { a[destination] = a[right]; destination -= 1; right -= 1 }
    } else if right < middle {
      while left >= 0 { a[destination] = a[left]; destination -= 1; left -= 1 }
    }
    return (left + 1, right + 1)
  }

  private func mergeMainPrefix(_ destinationStart: Int, _ leftEnd: Int,
                               _ middle: Int, _ end: Int) {
    var destination = destinationStart
    var left = 0
    var right = middle
    while left < leftEnd && right < end {
      if a[left] <= a[right] { a[destination] = a[left]; left += 1 }
      else { a[destination] = a[right]; right += 1 }
      destination += 1
    }
    while left < leftEnd { a[destination] = a[left]; destination += 1; left += 1 }
  }

  private func mergeExternal(_ destinationStart: Int, _ middle: Int, _ end: Int) {
    var destination = destinationStart
    var left = 0
    var right = middle
    while left < bufferLength && right < end {
      if buffer[left] <= a[right] { a[destination] = buffer[left]; left += 1 }
      else { a[destination] = a[right]; right += 1 }
      destination += 1
    }
    while left < bufferLength {
      a[destination] = buffer[left]
      destination += 1
      left += 1
    }
  }

  func sort() {
    guard n > 1 else { return }
    pingPong(0, bufferLength)
    var first = bufferLength
    for _ in 0..<4 {
      pingPong(first, first + chunk)
      first += chunk
    }
    for i in 0..<bufferLength { buffer[i] = a[i] }
    let twoFifths = 2 * chunk
    first = bufferLength
    for _ in 0..<2 {
      mergeForward(first - bufferLength, first, first + chunk, first + twoFifths)
      first += twoFifths
    }
    let (left, right) = mergeBackward(n - 1, twoFifths, 2 * twoFifths)
    if right > 0 { mergeMainPrefix(bufferLength, left, twoFifths, n) }
    mergeExternal(0, bufferLength, n)
  }
}

var example = FifthMerge([0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                          68, 83, 32, 56])
example.sort()
print(example.a)
