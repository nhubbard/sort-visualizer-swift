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

/// The external-buffer operations shared by ArrayV's block-merge sorts. Their destination ranges
/// are vacant when called, so reads must precede the corresponding main-array writes.
class BlockMergeSortingTemplate {
  var engine: RecordingEngine

  init(engine: RecordingEngine) { self.engine = engine }

  func shiftForwardExternal(_ destination: Int, _ source: Int, _ end: Int) {
    var output = destination
    var input = source
    while input < end {
      engine.setValue(output, engine.readValue(at: input))
      output += 1
      input += 1
    }
  }

  func shiftBackwardExternal(_ start: Int, _ sourceEnd: Int, _ destinationEnd: Int) {
    var input = sourceEnd
    var output = destinationEnd
    while input > start {
      input -= 1
      output -= 1
      engine.setValue(output, engine.readValue(at: input))
    }
  }

  func rightBinarySearch(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var lower = start
    var upper = end
    while lower < upper {
      let middle = lower + (upper - lower) / 2
      if engine.compareValue(middle, against: value, by: (<=)) {
        lower = middle + 1
      } else {
        upper = middle
      }
    }
    return lower
  }

  func binaryInsertion(_ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for index in (start + 1)..<end {
      let value = engine.readValue(at: index)
      let position = rightBinarySearch(start, index, value)
      var cursor = index
      while cursor > position {
        engine.setValue(cursor, engine.readValue(at: cursor - 1))
        cursor -= 1
      }
      if position != index { engine.setValue(position, value) }
    }
  }

  func multiSwap(_ first: Int, _ second: Int, _ length: Int) {
    guard length > 0 else { return }
    for offset in 0..<length { engine.swap(first + offset, second + offset) }
  }

  func mergeForwardExternal(_ start: Int, _ middle: Int, _ end: Int, _ destination: Int) {
    var left = start
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
    if left > output { shiftForwardExternal(output, left, middle) }
    shiftForwardExternal(output, right, end)
  }

  func mergeBackwardExternal(_ start: Int, _ middle: Int, _ end: Int, _ destinationEnd: Int) {
    var left = middle - 1
    var right = end - 1
    var output = destinationEnd
    while right >= middle && left >= start {
      output -= 1
      if engine.compare(right, left, by: (>=)) {
        engine.setValue(output, engine.readValue(at: right))
        right -= 1
      } else {
        engine.setValue(output, engine.readValue(at: left))
        left -= 1
      }
    }
    if output > right { shiftBackwardExternal(middle, right + 1, output) }
    shiftBackwardExternal(start, left + 1, output)
  }
}
