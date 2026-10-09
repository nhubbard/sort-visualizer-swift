import AlgorithmKit
import SortEngineKit

// The WikiSorting source is released to the public domain under the Unlicense.

/// Stable WikiSort using its default zero-cache path. It begins with balanced 4–8 element runs,
/// pulls distinct values from runs as internal block tags and merge storage, then restores them.
/// Low-distinctness runs use the source's rotation-based in-place merge fallback.
public struct WikiSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "wikisort")
  public let metadata = AlgorithmMetadata(
    displayName: "Wiki Sort",
    category: .hybrid,
    sizeRange: 16...994,
    growthModel: OperationGrowthModel(
      anchorSize: 994, coefficients: [224622, 292.102, 0.0406075],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [11.8124, 1.14772], rSquared: 0.99485),
    implementationComplexity: 170,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.up.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let worker = WikiRecorder(engine: engine)
    worker.sort()
    engine = worker.engine
  }
}

private struct WikiRange {
  var start: Int = 0
  var end: Int = 0
  var length: Int { end - start }
  init(_ start: Int = 0, _ end: Int = 0) { self.start = start; self.end = end }
  mutating func set(_ start: Int, _ end: Int) { self.start = start; self.end = end }
}

private struct WikiPull {
  var from = 0
  var to = 0
  var count = 0
  var range = WikiRange()
}

private struct WikiIterator {
  let size: Int
  let denominator: Int
  var numerator = 0
  var decimal = 0
  var numeratorStep: Int
  var decimalStep: Int

  init(size: Int) {
    self.size = size
    let power = 1 << (Int.bitWidth - 1 - size.leadingZeroBitCount)
    denominator = power / 4
    numeratorStep = size % denominator
    decimalStep = size / denominator
  }

  mutating func begin() { numerator = 0; decimal = 0 }
  mutating func nextRange() -> WikiRange {
    let start = decimal
    decimal += decimalStep
    numerator += numeratorStep
    if numerator >= denominator { numerator -= denominator; decimal += 1 }
    return WikiRange(start, decimal)
  }
  var finished: Bool { decimal >= size }
  mutating func nextLevel() -> Bool {
    decimalStep += decimalStep
    numeratorStep += numeratorStep
    if numeratorStep >= denominator { numeratorStep -= denominator; decimalStep += 1 }
    return decimalStep < size
  }
  var length: Int { decimalStep }
}

private final class WikiRecorder {
  var engine: RecordingEngine
  init(engine: RecordingEngine) { self.engine = engine }

  private func read(_ index: Int) -> Int { engine.readValue(at: index) }
  private func less(_ left: Int, _ right: Int) -> Bool {
    engine.teachingCompare(
      left, right, by: (<),
      stageID: "WikiSort.key.order",
      whenTrue: "The first key is smaller, so WikiSort orders it before the second.",
      whenFalse: "The first key is not smaller, so WikiSort checks another ordering.")
  }
  private func lessValues(_ left: Int, _ right: Int) -> Bool { engine.compareValues(left, right, by: (<)) }
  private func greaterValues(_ left: Int, _ right: Int) -> Bool { engine.compareValues(left, right, by: (>)) }
  private func swap(_ left: Int, _ right: Int) { engine.swap(left, right) }

  private func binaryFirst(_ value: Int, _ range: WikiRange) -> Int {
    var start = range.start
    var end = range.end
    while start < end {
      let middle = start + (end - start) / 2
      if engine.compareValue(middle, against: value, by: (<)) { start = middle + 1 }
      else { end = middle }
    }
    return start
  }

  private func binaryLast(_ value: Int, _ range: WikiRange) -> Int {
    var start = range.start
    var end = range.end
    while start < end {
      let middle = start + (end - start) / 2
      if engine.compareValue(middle, against: value, by: (<=)) { start = middle + 1 }
      else { end = middle }
    }
    return start
  }

  private func findFirstForward(_ value: Int, _ range: WikiRange, _ unique: Int) -> Int {
    guard range.length > 0 else { return range.start }
    let skip = max(range.length / max(unique, 1), 1)
    var index = range.start + skip
    while engine.compareValue(index - 1, against: value, by: (<)) {
      if index >= range.end - skip { return binaryFirst(value, WikiRange(index, range.end)) }
      index += skip
    }
    return binaryFirst(value, WikiRange(index - skip, index))
  }

  private func findLastForward(_ value: Int, _ range: WikiRange, _ unique: Int) -> Int {
    guard range.length > 0 else { return range.start }
    let skip = max(range.length / max(unique, 1), 1)
    var index = range.start + skip
    while engine.compareValue(index - 1, against: value, by: (<=)) {
      if index >= range.end - skip { return binaryLast(value, WikiRange(index, range.end)) }
      index += skip
    }
    return binaryLast(value, WikiRange(index - skip, index))
  }

  private func findFirstBackward(_ value: Int, _ range: WikiRange, _ unique: Int) -> Int {
    guard range.length > 0 else { return range.start }
    let skip = max(range.length / max(unique, 1), 1)
    var index = range.end - skip
    while index > range.start && engine.compareValue(index - 1, against: value, by: (>=)) {
      if index < range.start + skip { return binaryFirst(value, WikiRange(range.start, index)) }
      index -= skip
    }
    return binaryFirst(value, WikiRange(index, index + skip))
  }

  private func findLastBackward(_ value: Int, _ range: WikiRange, _ unique: Int) -> Int {
    guard range.length > 0 else { return range.start }
    let skip = max(range.length / max(unique, 1), 1)
    var index = range.end - skip
    while index > range.start && engine.compareValue(index - 1, against: value, by: (>)) {
      if index < range.start + skip { return binaryLast(value, WikiRange(range.start, index)) }
      index -= skip
    }
    return binaryLast(value, WikiRange(index, index + skip))
  }

  private func insertionSort(_ range: WikiRange) {
    guard range.length > 1 else { return }
    for index in (range.start + 1)..<range.end {
      let value = read(index)
      let destination = binaryLast(value, WikiRange(range.start, index))
      var cursor = index
      while cursor > destination {
        engine.setValue(cursor, read(cursor - 1))
        cursor -= 1
      }
      engine.setValue(destination, value)
    }
  }

  private func blockSwap(_ first: Int, _ second: Int, _ length: Int) {
    guard length > 0 else { return }
    for offset in 0..<length { swap(first + offset, second + offset) }
  }

  private func rotate(_ amount: Int, _ range: WikiRange) {
    guard range.length > 0 else { return }
    let split = amount >= 0 ? range.start + amount : range.end + amount
    guard range.start < split && split < range.end else { return }
    GrailSortingTemplate.rotate(&engine, range.start, split - range.start, range.end - split)
  }

  private func mergeInternal(_ left: WikiRange, _ right: WikiRange, _ buffer: WikiRange) {
    var aCount = 0
    var bCount = 0
    var insert = 0
    if right.length > 0 && left.length > 0 {
      while true {
        if !less(right.start + bCount, buffer.start + aCount) {
          swap(left.start + insert, buffer.start + aCount)
          aCount += 1
          insert += 1
          if aCount >= left.length { break }
        } else {
          swap(left.start + insert, right.start + bCount)
          bCount += 1
          insert += 1
          if bCount >= right.length { break }
        }
      }
    }
    blockSwap(buffer.start + aCount, left.start + insert, left.length - aCount)
  }

  private func mergeInPlace(_ originalLeft: WikiRange, _ originalRight: WikiRange) {
    guard originalLeft.length > 0 && originalRight.length > 0 else { return }
    var left = originalLeft
    var right = originalRight
    while true {
      let middle = binaryFirst(read(left.start), right)
      let amount = middle - left.end
      rotate(-amount, WikiRange(left.start, middle))
      if right.end == middle { break }
      right.start = middle
      left.set(left.start + amount, right.start)
      left.start = binaryLast(read(left.start), left)
      if left.length == 0 { break }
    }
  }

  private func netSwap(_ range: WikiRange, _ order: inout [Int], _ x: Int, _ y: Int) {
    let first = range.start + x
    let second = range.start + y
    let a = read(first)
    let b = read(second)
    let isGreater = greaterValues(a, b)
    let isEqual = !isGreater && !lessValues(a, b)
    if isGreater || (isEqual && order[x] > order[y]) {
      swap(first, second)
      order.swapAt(x, y)
    }
  }

  private func sortSmallRuns(_ iterator: inout WikiIterator) {
    while !iterator.finished {
      var order = Array(0..<8)
      let range = iterator.nextRange()
      let pairs: [(Int, Int)]
      switch range.length {
      case 8: pairs = [(0,1),(2,3),(4,5),(6,7),(0,2),(1,3),(4,6),(5,7),(1,2),(5,6),(0,4),(3,7),(1,5),(2,6),(1,4),(3,6),(2,4),(3,5),(3,4)]
      case 7: pairs = [(1,2),(3,4),(5,6),(0,2),(3,5),(4,6),(0,1),(4,5),(2,6),(0,4),(1,5),(0,3),(2,5),(1,3),(2,4),(2,3)]
      case 6: pairs = [(1,2),(4,5),(0,2),(3,5),(0,1),(3,4),(2,5),(0,3),(1,4),(2,4),(1,3),(2,3)]
      case 5: pairs = [(0,1),(3,4),(2,4),(2,3),(1,4),(0,3),(0,2),(1,3),(1,2)]
      case 4: pairs = [(0,1),(2,3),(0,2),(1,3),(1,2)]
      default: pairs = []
      }
      for (x, y) in pairs { netSwap(range, &order, x, y) }
    }
  }

  func sort() {
    let size = engine.count
    if size < 4 {
      insertionSort(WikiRange(0, size))
      return
    }
    var iterator = WikiIterator(size: size)
    sortSmallRuns(&iterator)
    if size < 8 { return }

    while true {
      let nominalBlock = max(1, Int(Double(iterator.length).squareRoot()))
      var blockSize = nominalBlock
      let targetBufferSize = iterator.length / blockSize + 1
      var buffer1 = WikiRange()
      var buffer2 = WikiRange()
      var pulls = [WikiPull(), WikiPull()]
      var pullIndex = 0
      var find = targetBufferSize * 2
      var findSeparately = false
      if find > iterator.length { find = targetBufferSize; findSeparately = true }

      iterator.begin()
      search: while !iterator.finished {
        let left = iterator.nextRange()
        let right = iterator.nextRange()
        var last = left.start
        var count = 1
        var index = last
        while count < find {
          index = findLastForward(read(last), WikiRange(last + 1, left.end), find - count)
          if index == left.end { break }
          last = index
          count += 1
        }
        index = last
        if count >= targetBufferSize {
          pulls[pullIndex] = WikiPull(from: index, to: left.start, count: count, range: WikiRange(left.start, right.end))
          pullIndex = 1
          if count == targetBufferSize * 2 {
            buffer1 = WikiRange(left.start, left.start + targetBufferSize)
            buffer2 = WikiRange(left.start + targetBufferSize, left.start + count)
            break search
          } else if find == targetBufferSize * 2 {
            buffer1 = WikiRange(left.start, left.start + count)
            find = targetBufferSize
          } else if findSeparately {
            buffer1 = WikiRange(left.start, left.start + count)
            findSeparately = false
          } else {
            buffer2 = WikiRange(left.start, left.start + count)
            break search
          }
        } else if pullIndex == 0 && count > buffer1.length {
          buffer1 = WikiRange(left.start, left.start + count)
          pulls[pullIndex] = WikiPull(from: index, to: left.start, count: count, range: WikiRange(left.start, right.end))
        }

        last = right.end - 1
        count = 1
        while count < find {
          index = findFirstBackward(read(last), WikiRange(right.start, last), find - count)
          if index == right.start { break }
          last = index - 1
          count += 1
        }
        index = last
        if count >= targetBufferSize {
          pulls[pullIndex] = WikiPull(from: index, to: right.end, count: count, range: WikiRange(left.start, right.end))
          pullIndex = 1
          if count == targetBufferSize * 2 {
            buffer1 = WikiRange(right.end - count, right.end - targetBufferSize)
            buffer2 = WikiRange(right.end - targetBufferSize, right.end)
            break search
          } else if find == targetBufferSize * 2 {
            buffer1 = WikiRange(right.end - count, right.end)
            find = targetBufferSize
          } else if findSeparately {
            buffer1 = WikiRange(right.end - count, right.end)
            findSeparately = false
          } else {
            if pulls[0].range.start == left.start { pulls[0].range.end -= pulls[1].count }
            buffer2 = WikiRange(right.end - count, right.end)
            break search
          }
        } else if pullIndex == 0 && count > buffer1.length {
          buffer1 = WikiRange(right.end - count, right.end)
          pulls[pullIndex] = WikiPull(from: index, to: right.end, count: count, range: WikiRange(left.start, right.end))
        }
      }

      for pull in 0..<2 {
        let length = pulls[pull].count
        if pulls[pull].to < pulls[pull].from {
          var index = pulls[pull].from
          if length > 1 {
            for count in 1..<length {
              index = findFirstBackward(read(index - 1), WikiRange(pulls[pull].to, pulls[pull].from - (count - 1)), length - count)
              let range = WikiRange(index + 1, pulls[pull].from + 1)
              rotate(range.length - count, range)
              pulls[pull].from = index + count
            }
          }
        } else if pulls[pull].to > pulls[pull].from {
          var index = pulls[pull].from + 1
          if length > 1 {
            for count in 1..<length {
              index = findLastForward(read(index), WikiRange(index, pulls[pull].to), length - count)
              let range = WikiRange(pulls[pull].from, index - 1)
              rotate(count, range)
              pulls[pull].from = index - 1 - count
            }
          }
        }
      }

      let bufferSize = buffer1.length
      blockSize = iterator.length / bufferSize + 1
      iterator.begin()
      while !iterator.finished {
        var left = iterator.nextRange()
        var right = iterator.nextRange()
        let start = left.start
        for pull in pulls where start == pull.range.start {
          if pull.from > pull.to { left.start += pull.count }
          else if pull.from < pull.to { right.end -= pull.count }
        }
        if left.length == 0 || right.length == 0 { continue }

        if less(right.end - 1, left.start) {
          rotate(left.length, WikiRange(left.start, right.end))
        } else if less(left.end, left.end - 1) {
          var blockA = left
          let firstA = WikiRange(left.start, left.start + blockA.length % blockSize)
          var indexA = buffer1.start
          var index = firstA.end
          while index < blockA.end {
            swap(indexA, index)
            indexA += 1
            index += blockSize
          }

          var lastA = firstA
          var lastB = WikiRange()
          var blockB = WikiRange(right.start, right.start + min(blockSize, right.length))
          blockA.start += firstA.length
          indexA = buffer1.start
          if buffer2.length > 0 { blockSwap(lastA.start, buffer2.start, lastA.length) }

          if blockA.length > 0 {
            while true {
              if (lastB.length > 0 && !less(lastB.end - 1, indexA)) || blockB.length == 0 {
                let split = binaryFirst(read(indexA), lastB)
                let remaining = lastB.end - split
                var minimum = blockA.start
                var findA = minimum + blockSize
                while findA < blockA.end {
                  if less(findA, minimum) { minimum = findA }
                  findA += blockSize
                }
                blockSwap(blockA.start, minimum, blockSize)
                swap(blockA.start, indexA)
                indexA += 1
                if buffer2.length > 0 { mergeInternal(lastA, WikiRange(lastA.end, split), buffer2) }
                else { mergeInPlace(lastA, WikiRange(lastA.end, split)) }
                if buffer2.length > 0 {
                  blockSwap(blockA.start, buffer2.start, blockSize)
                  blockSwap(split, blockA.start + blockSize - remaining, remaining)
                } else {
                  rotate(blockA.start - split, WikiRange(split, blockA.start + blockSize))
                }
                lastA = WikiRange(blockA.start - remaining, blockA.start - remaining + blockSize)
                lastB = WikiRange(lastA.end, lastA.end + remaining)
                blockA.start += blockSize
                if blockA.length == 0 { break }
              } else if blockB.length < blockSize {
                rotate(-blockB.length, WikiRange(blockA.start, blockB.end))
                lastB = WikiRange(blockA.start, blockA.start + blockB.length)
                blockA.start += blockB.length
                blockA.end += blockB.length
                blockB.end = blockB.start
              } else {
                blockSwap(blockA.start, blockB.start, blockSize)
                lastB = WikiRange(blockA.start, blockA.start + blockSize)
                blockA.start += blockSize
                blockA.end += blockSize
                blockB.start += blockSize
                blockB.end = min(blockB.end + blockSize, right.end)
              }
            }
          }
          if buffer2.length > 0 { mergeInternal(lastA, WikiRange(lastA.end, right.end), buffer2) }
          else { mergeInPlace(lastA, WikiRange(lastA.end, right.end)) }
        }
      }

      insertionSort(buffer2)
      for pull in pulls {
        var unique = pull.count * 2
        if pull.from > pull.to {
          var buffer = WikiRange(pull.range.start, pull.range.start + pull.count)
          while buffer.length > 0 {
            let index = findFirstForward(read(buffer.start), WikiRange(buffer.end, pull.range.end), unique)
            let amount = index - buffer.end
            rotate(buffer.length, WikiRange(buffer.start, index))
            buffer.start += amount + 1
            buffer.end += amount
            unique -= 2
          }
        } else if pull.from < pull.to {
          var buffer = WikiRange(pull.range.end - pull.count, pull.range.end)
          while buffer.length > 0 {
            let index = findLastBackward(read(buffer.end - 1), WikiRange(pull.range.start, buffer.start), unique)
            let amount = buffer.start - index
            rotate(amount, WikiRange(index, buffer.end))
            buffer.start -= amount
            buffer.end -= amount + 1
            unique -= 2
          }
        }
      }
      if !iterator.nextLevel() { break }
    }
  }
}
