import AlgorithmKit
import SortEngineKit

// MIT License
// Copyright (c) 2020-2021 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/// A port of aphitorite's Ecta Sort. It saves a sorted prefix in an external buffer, sorts the
/// remainder using that prefix as workspace, then merges the large runs through alternating
/// forward and backward block cycles. Tags record the block permutation independently of the
/// main array. The short-run sorter uses stable binary insertion in place of ArrayV's binary
/// double insertion helper; both establish the same sorted runs before Ecta's merge phases.
public struct EctaSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "ectasort")
  public let metadata = AlgorithmMetadata(
    displayName: "Ecta Sort",
    category: .hybrid,
    sizeRange: 16...1446,
    growthModel: OperationGrowthModel(
      anchorSize: 1446, coefficients: [239692, 312.599, 0.101583],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.101583, 18.8222, 73.7008], rSquared: 0.997671),
    implementationComplexity: 140,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(√n)",
    iconName: "square.stack.3d.up"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length > 1 else { return }

    func minRun(_ n: Int) -> Int {
      var run = n
      while run >= 32 { run = (run + 1) / 2 }
      return run
    }

    func insertion(_ start: Int, _ end: Int) {
      guard end - start > 1 else { return }
      for index in (start + 1)..<end {
        let value = engine.readValue(at: index)
        var low = start
        var high = index
        while low < high {
          let mid = low + (high - low) / 2
          if engine.teachingCompareValue(
            mid, against: value, by: (>),
            stageID: "EctaSort.binary.search",
            whenTrue: "This run value exceeds the held value, so the insertion point lies to the left.",
            whenFalse: "This run value does not exceed the held value, so the search moves right."
          ) {
            high = mid
          } else {
            low = mid + 1
          }
        }
        var cursor = index
        while cursor > low {
          engine.setValue(cursor, engine.readValue(at: cursor - 1))
          cursor -= 1
        }
        if low != index { engine.setValue(low, value) }
      }
    }

    if length <= 32 {
      insertion(0, length)
      return
    }

    let blockLength: Int
    let bufferLength: Int
    if length < 256 {
      blockLength = 0
      bufferLength = length / 2
    } else {
      var block = minRun(length)
      while block * block < length / 2 { block *= 2 }
      blockLength = block
      bufferLength = 2 * block + length % block
    }
    let bufferHandle = engine.createAuxArray(length: bufferLength)
    var buffer = Array(repeating: 0, count: bufferLength)
    let tagCount = blockLength == 0 ? 0 : (length - bufferLength) / blockLength + 1
    let tagHandle = tagCount == 0 ? nil : engine.createAuxArray(length: tagCount)
    var tags = Array(repeating: 0, count: tagCount)

    func writeBuffer(_ index: Int, _ value: Int) {
      buffer[index] = value
      engine.writeAux(bufferHandle, at: index, value: value)
    }
    func readBuffer(_ index: Int) -> Int {
      engine.markAuxRead(bufferHandle, at: index)
      return buffer[index]
    }
    func writeTag(_ index: Int, _ value: Int) {
      tags[index] = value
      engine.writeAux(tagHandle!, at: index, value: value)
    }
    func readTag(_ index: Int) -> Int {
      engine.markAuxRead(tagHandle!, at: index)
      return tags[index]
    }
    func copyMain(_ source: Int, _ destination: Int, _ count: Int) {
      guard count > 0 else { return }
      let values = engine.readValues(in: source..<(source + count))
      for offset in 0..<count { engine.setValue(destination + offset, values[offset]) }
    }
    func copyMainToBuffer(_ source: Int, _ destination: Int, _ count: Int) {
      for offset in 0..<count {
        writeBuffer(destination + offset, engine.readValue(at: source + offset))
      }
    }
    func copyBufferToMain(_ source: Int, _ destination: Int, _ count: Int) {
      for offset in 0..<count { engine.setValue(destination + offset, readBuffer(source + offset)) }
    }
    func shift(_ a: Int, _ middle: Int, _ end: Int) {
      var destination = a
      for source in middle..<end {
        engine.setValue(destination, engine.readValue(at: source))
        destination += 1
      }
    }
    func shiftBackward(_ a: Int, _ middle: Int, _ end: Int) {
      var destination = end
      for source in stride(from: middle - 1, through: a, by: -1) {
        destination -= 1
        engine.setValue(destination, engine.readValue(at: source))
      }
    }
    func mergeTo(_ a: Int, _ middle: Int, _ end: Int, _ destination: Int) {
      var left = a
      var right = middle
      var output = destination
      while left < middle && right < end {
        if engine.compare(left, right, by: (<=)) {
          engine.setValue(output, engine.readValue(at: left))
          left += 1
        } else {
          engine.setValue(output, engine.readValue(at: right))
          right += 1
        }
        output += 1
      }
      while left < middle {
        engine.setValue(output, engine.readValue(at: left))
        left += 1
        output += 1
      }
      while right < end {
        engine.setValue(output, engine.readValue(at: right))
        right += 1
        output += 1
      }
    }
    func pingPongMerge(_ a: Int, _ m1: Int, _ m2: Int, _ m3: Int, _ end: Int, _ workspace: Int) {
      let second = workspace + m2 - a
      mergeTo(a, m1, m2, workspace)
      mergeTo(m2, m3, end, second)
      mergeTo(workspace, second, workspace + end - a, a)
    }
    func mergeBackward(_ a: Int, _ middle: Int, _ end: Int, _ workspace: Int) {
      let count = end - middle
      copyMain(middle, workspace, count)
      var left = middle - 1
      var right = workspace + count - 1
      var output = end
      while left >= a && right >= workspace {
        output -= 1
        if engine.compare(left, right, by: (>)) {
          engine.setValue(output, engine.readValue(at: left))
          left -= 1
        } else {
          engine.setValue(output, engine.readValue(at: right))
          right -= 1
        }
      }
      while right >= workspace {
        output -= 1
        engine.setValue(output, engine.readValue(at: right))
        right -= 1
      }
    }
    func mergeFromBuffer(_ start: Int, _ middle: Int, _ end: Int, _ count: Int) {
      var index = 0
      var right = middle
      var output = start
      while index < count && right < end {
        let held = readBuffer(index)
        if engine.compareValue(right, against: held, by: (>=)) {
          engine.setValue(output, held)
          index += 1
        } else {
          engine.setValue(output, engine.readValue(at: right))
          right += 1
        }
        output += 1
      }
      while index < count {
        engine.setValue(output, readBuffer(index))
        index += 1
        output += 1
      }
    }
    func dualMergeFromBufferBackward(
      _ start: Int, _ first: Int, _ middle: Int, _ end: Int, _ count: Int
    ) {
      var index = count - 1
      let split = count - (end - middle)
      var left = middle - 1
      var output = end
      while index >= split && left >= first {
        output -= 1
        let held = readBuffer(index)
        if engine.compareValue(left, against: held, by: (<)) {
          engine.setValue(output, held)
          index -= 1
        } else {
          engine.setValue(output, engine.readValue(at: left))
          left -= 1
        }
      }
      if left < first {
        while index >= 0 {
          output -= 1
          engine.setValue(output, readBuffer(index))
          index -= 1
        }
      } else {
        mergeFromBuffer(start, first, output, split)
      }
    }
    func mergeSort(_ start: Int, _ end: Int, _ workspace: Int, _ initialRun: Int, _ capacity: Int) -> Int {
      var index = start
      var run = initialRun
      while index + run <= end {
        insertion(index, index + run)
        index += run
      }
      insertion(index, end)
      while 4 * run <= capacity {
        index = start
        while index + 4 * run <= end {
          pingPongMerge(index, index + run, index + 2 * run, index + 3 * run, index + 4 * run, workspace)
          index += 4 * run
        }
        if index + 3 * run < end {
          pingPongMerge(index, index + run, index + 2 * run, index + 3 * run, end, workspace)
        } else if index + 2 * run < end {
          pingPongMerge(index, index + run, index + 2 * run, end, end, workspace)
        } else if index + run < end {
          mergeBackward(index, index + run, end, workspace)
        }
        run *= 4
      }
      while run <= capacity {
        index = start
        while index + 2 * run <= end {
          mergeBackward(index, index + run, index + 2 * run, workspace)
          index += 2 * run
        }
        if index + run < end { mergeBackward(index, index + run, end, workspace) }
        run *= 2
      }
      return run
    }

    if length < 256 {
      copyMainToBuffer(bufferLength, 0, bufferLength)
      _ = mergeSort(0, bufferLength, bufferLength, minRun(length), bufferLength)
      copyBufferToMain(0, bufferLength, bufferLength)
      copyMainToBuffer(0, 0, bufferLength)
      _ = mergeSort(bufferLength, length, 0, minRun(length), bufferLength)
      mergeFromBuffer(0, bufferLength, length, bufferLength)
      engine.deleteAuxArray(bufferHandle)
      return
    }

    func blockCycle(_ start: Int, _ block: Int, _ count: Int, _ workspace: Int, _ excludeLast: Bool, _ forward: Bool) {
      let strideSize = forward ? block : -block
      for index in 0..<count {
        var next = readTag(index)
        if index != next {
          copyMain(start + index * strideSize, workspace, block)
          var current = index
          while true {
            if !(excludeLast && current == count - 1) {
              copyMain(start + next * strideSize, start + current * strideSize, block)
            }
            writeTag(current, current)
            current = next
            next = readTag(next)
            if next == index { break }
          }
          copyMain(workspace, start + current * strideSize, block)
          writeTag(current, current)
        }
      }
    }
    func ectaMergeForward(_ start: Int, _ middle: Int, _ end: Int, _ block: Int) {
      var left = start
      var right = middle
      var tag = 0
      var tagCount = 0
      var saved = 2 * block
      var other = 0
      var savedPosition = start - 2 * block
      var otherPosition = middle
      repeat {
        let choice = saved < block ? 1 : 0
        for offset in 0..<block {
          let destination = (choice == 0 ? savedPosition : otherPosition) + offset
          if left < middle && right < end {
            if engine.compare(left, right, by: (<=)) {
              engine.setValue(destination, engine.readValue(at: left))
              left += 1
              saved += 1
            } else {
              engine.setValue(destination, engine.readValue(at: right))
              right += 1
              other += 1
            }
          } else if left < middle {
            engine.setValue(destination, engine.readValue(at: left))
            left += 1
            saved += 1
          } else {
            engine.setValue(destination, engine.readValue(at: right))
            right += 1
            other += 1
          }
        }
        if choice == 0 {
          savedPosition += block
          saved -= block
        } else {
          otherPosition += block
          other -= block
        }
        writeTag(tagCount, choice == 0 ? tag : -1)
        tagCount += 1
        if choice == 0 { tag += 1 }
      } while left < middle || right < end
      if saved > 0 { writeTag(tagCount, tag); tag += 1 }
      if tagCount > 2 {
        for index in 2..<tagCount where readTag(index) == -1 {
          writeTag(index, tag)
          tag += 1
        }
      }
      blockCycle(start - 2 * block, block, tag, end - block, saved > 0, true)
    }
    func ectaMergeBackward(_ start: Int, _ middle: Int, _ end: Int, _ block: Int) {
      var right = end - 1
      var left = middle - 1
      var tag = 0
      var tagCount = 0
      var saved = 2 * block
      var other = 0
      var savedPosition = end + 2 * block
      var otherPosition = middle
      repeat {
        let choice = saved < block ? 1 : 0
        for offset in 1...block {
          let destination = (choice == 0 ? savedPosition : otherPosition) - offset
          if right >= middle && left >= start {
            if engine.compare(right, left, by: (>=)) {
              engine.setValue(destination, engine.readValue(at: right))
              right -= 1
              saved += 1
            } else {
              engine.setValue(destination, engine.readValue(at: left))
              left -= 1
              other += 1
            }
          } else if right >= middle {
            engine.setValue(destination, engine.readValue(at: right))
            right -= 1
            saved += 1
          } else {
            engine.setValue(destination, engine.readValue(at: left))
            left -= 1
            other += 1
          }
        }
        if choice == 0 {
          savedPosition -= block
          saved -= block
        } else {
          otherPosition -= block
          other -= block
        }
        writeTag(tagCount, choice == 0 ? tag : -1)
        tagCount += 1
        if choice == 0 { tag += 1 }
      } while right >= middle || left >= start
      if saved > 0 { writeTag(tagCount, tag); tag += 1 }
      if tagCount > 2 {
        for index in 2..<tagCount where readTag(index) == -1 {
          writeTag(index, tag)
          tag += 1
        }
      }
      blockCycle(end + block, block, tag, start, saved > 0, false)
    }

    var start = bufferLength
    var end = length
    let dataLength = end - start
    copyMainToBuffer(start, 0, bufferLength)
    _ = mergeSort(0, start, start, minRun(bufferLength), bufferLength)
    copyBufferToMain(0, start, bufferLength)
    copyMainToBuffer(0, 0, bufferLength)
    var run = mergeSort(start, end, 0, minRun(length), bufferLength)
    var backward = false
    while run < dataLength {
      var index = start
      while index + 2 * run <= end {
        ectaMergeForward(index, index + run, index + 2 * run, blockLength)
        index += 2 * run
      }
      if index + run < end {
        ectaMergeForward(index, index + run, end, blockLength)
      } else {
        shift(index - 2 * blockLength, index, end)
      }
      run *= 2
      start -= 2 * blockLength
      end -= 2 * blockLength
      if run >= dataLength {
        backward = true
        break
      }
      index = start
      while index + 2 * run <= end { index += 2 * run }
      if index + run < end {
        ectaMergeBackward(index, index + run, end, blockLength)
      } else {
        shiftBackward(index, end, end + 2 * blockLength)
      }
      index -= 2 * run
      while index >= start {
        ectaMergeBackward(index, index + run, index + 2 * run, blockLength)
        index -= 2 * run
      }
      run *= 2
      start += 2 * blockLength
      end += 2 * blockLength
    }
    if backward {
      dualMergeFromBufferBackward(0, start, end, length, bufferLength)
    } else {
      mergeFromBuffer(0, start, end, bufferLength)
    }
    engine.deleteAuxArray(bufferHandle)
    engine.deleteAuxArray(tagHandle!)
  }
}
