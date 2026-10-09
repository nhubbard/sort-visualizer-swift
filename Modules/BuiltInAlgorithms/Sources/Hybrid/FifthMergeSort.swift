import AlgorithmKit
import SortEngineKit

/// A stable five-way hybrid merge sort. The input is divided into one prefix of
/// `ceil(n / 5)` elements and four equal-sized following chunks. Each chunk is sorted by binary
/// insertion and ping-pong merging, after which the prefix is moved into the only external
/// buffer and its vacated positions become an internal merge buffer for the four remaining
/// chunks.
///
/// Forward merges fill space that has already been vacated, while the central backward merge
/// fills the array from its end. Those direction invariants prevent an unread value from being
/// overwritten. Forward merges select the left run on equal keys; backward merges select the
/// right run on equal keys because they write from right to left. Both choices preserve the
/// original order of equal elements, so the complete algorithm is stable.
public struct FifthMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "fifthmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Fifth Merge Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2029, coefficients: [239885, 203.536, 0.0419632],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0419632, 33.2496, -334.491], rSquared: 0.999287),
    implementationComplexity: 65,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"
    ),
    spaceComplexity: "O(n)",
    iconName: "rectangle.split.3x1"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let fifthLength = n / 5
    let bufferLength = n - fifthLength * 4
    let handle = engine.createAuxArray(length: bufferLength)
    var buffer = AuxBuffer(handle: handle, length: bufferLength)

    func readAux(_ index: Int) -> Int {
      engine.markAuxRead(handle, at: index)
      return buffer.values[index]
    }

    func binaryInsertionSort(_ start: Int, _ end: Int) {
      guard end - start > 1 else { return }
      for i in (start + 1)..<end {
        let value = engine.readValue(at: i)
        var low = start
        var high = i
        while low < high {
          let middle = low + (high - low) / 2
          if engine.teachingCompareValue(
            middle, against: value, by: >,
            stageID: "FifthMergeSort.binary.search",
            whenTrue: "This run value exceeds the held value, so the insertion point lies to the left.",
            whenFalse: "This run value does not exceed the held value, so the search moves right."
          ) {
            high = middle
          } else {
            low = middle + 1
          }
        }
        var j = i
        while j > low {
          engine.setValue(j, engine.readValue(at: j - 1))
          j -= 1
        }
        engine.setValue(low, value)
      }
    }

    func merge(
      chunkOffset: Int, start: Int, middle: Int, end: Int, fromBuffer: Bool
    ) {
      var left = start
      var right = middle
      var destination = fromBuffer ? start : start - chunkOffset

      func sourceValue(_ index: Int) -> Int {
        fromBuffer ? readAux(index - chunkOffset) : engine.readValue(at: index)
      }

      func leftPrecedesRight(_ left: Int, _ right: Int) -> Bool {
        if fromBuffer {
          let leftValue = readAux(left - chunkOffset)
          let rightValue = readAux(right - chunkOffset)
          return engine.compareValues(leftValue, rightValue, by: <=)
        }
        return engine.compare(left, right, by: <=)
      }

      func writeDestination(_ value: Int) {
        if fromBuffer {
          engine.setValue(destination, value)
        } else {
          buffer.write(&engine, at: destination, value: value)
        }
        destination += 1
      }

      while left < middle && right < end {
        if leftPrecedesRight(left, right) {
          writeDestination(sourceValue(left))
          left += 1
        } else {
          writeDestination(sourceValue(right))
          right += 1
        }
      }
      while left < middle {
        writeDestination(sourceValue(left))
        left += 1
      }
      while right < end {
        writeDestination(sourceValue(right))
        right += 1
      }
    }

    func pingPong(_ start: Int, _ end: Int) {
      var i = start
      while i + 8 < end {
        binaryInsertionSort(i, i + 8)
        i += 8
      }
      if end - i > 1 {
        binaryInsertionSort(i, end)
      }

      let length = end - start
      var fromBuffer = false
      var gap = 8
      while gap < length {
        let fullMerge = gap * 2
        i = start
        while i + fullMerge < end {
          merge(
            chunkOffset: start, start: i, middle: i + gap, end: i + fullMerge,
            fromBuffer: fromBuffer
          )
          i += fullMerge
        }
        if i + gap < end {
          merge(
            chunkOffset: start, start: i, middle: i + gap, end: end,
            fromBuffer: fromBuffer
          )
        } else if fromBuffer {
          for index in i..<end {
            engine.setValue(index, readAux(index - start))
          }
        } else {
          for index in i..<end {
            buffer.write(&engine, at: index - start, value: engine.readValue(at: index))
          }
        }
        fromBuffer.toggle()
        gap *= 2
      }

      if fromBuffer {
        for offset in 0..<length {
          engine.setValue(start + offset, readAux(offset))
        }
      }
    }

    func mergeInPlaceForwards(destination: Int, start: Int, middle: Int, end: Int) {
      var destination = destination
      var left = start
      var right = middle
      while left < middle && right < end {
        if engine.compare(left, right, by: <=) {
          engine.setValue(destination, engine.readValue(at: left))
          left += 1
        } else {
          engine.setValue(destination, engine.readValue(at: right))
          right += 1
        }
        destination += 1
      }
      while left < middle {
        engine.setValue(destination, engine.readValue(at: left))
        left += 1
        destination += 1
      }
      while right < end {
        engine.setValue(destination, engine.readValue(at: right))
        right += 1
        destination += 1
      }
    }

    func mergeInPlaceBackwards(destination: Int, middle: Int, end: Int) -> (left: Int, right: Int) {
      var destination = destination
      var left = middle - 1
      var right = end - 1
      while destination > right && right >= middle && left >= 0 {
        if engine.compare(left, right, by: >) {
          engine.setValue(destination, engine.readValue(at: left))
          left -= 1
        } else {
          engine.setValue(destination, engine.readValue(at: right))
          right -= 1
        }
        destination -= 1
      }
      if left < 0 {
        while right >= middle {
          engine.setValue(destination, engine.readValue(at: right))
          right -= 1
          destination -= 1
        }
      } else if right == left {
        while right >= 0 {
          engine.setValue(destination, engine.readValue(at: right))
          right -= 1
          destination -= 1
        }
      } else if right < middle {
        while left >= 0 {
          engine.setValue(destination, engine.readValue(at: left))
          left -= 1
          destination -= 1
        }
      }
      return (left + 1, right + 1)
    }

    func mergeForwardsWithMainPrefix(
      destination: Int, leftEnd: Int, middle: Int, end: Int
    ) {
      var destination = destination
      var left = 0
      var right = middle
      while left < leftEnd && right < end {
        if engine.compare(left, right, by: <=) {
          engine.setValue(destination, engine.readValue(at: left))
          left += 1
        } else {
          engine.setValue(destination, engine.readValue(at: right))
          right += 1
        }
        destination += 1
      }
      while left < leftEnd {
        engine.setValue(destination, engine.readValue(at: left))
        left += 1
        destination += 1
      }
    }

    func mergeForwardsWithExternalBuffer(destination: Int, middle: Int, end: Int) {
      var destination = destination
      var left = 0
      var right = middle
      while left < bufferLength && right < end {
        let leftValue = readAux(left)
        if engine.compareValue(right, against: leftValue, by: { rightValue, bufferedValue in
          bufferedValue <= rightValue
        }) {
          engine.setValue(destination, readAux(left))
          left += 1
        } else {
          engine.setValue(destination, engine.readValue(at: right))
          right += 1
        }
        destination += 1
      }
      while left < bufferLength {
        engine.setValue(destination, readAux(left))
        left += 1
        destination += 1
      }
    }

    pingPong(0, bufferLength)
    var start = bufferLength
    for _ in 0..<4 {
      pingPong(start, start + fifthLength)
      start += fifthLength
    }

    for index in 0..<bufferLength {
      buffer.write(&engine, at: index, value: engine.readValue(at: index))
    }

    let twoFifths = 2 * fifthLength
    start = bufferLength
    for _ in 0..<2 {
      mergeInPlaceForwards(
        destination: start - bufferLength,
        start: start,
        middle: start + fifthLength,
        end: start + twoFifths
      )
      start += twoFifths
    }

    let finalMerge = mergeInPlaceBackwards(
      destination: n - 1, middle: twoFifths, end: 2 * twoFifths
    )
    if finalMerge.right > 0 {
      mergeForwardsWithMainPrefix(
        destination: bufferLength, leftEnd: finalMerge.left, middle: twoFifths, end: n
      )
    }

    mergeForwardsWithExternalBuffer(destination: 0, middle: bufferLength, end: n)
    engine.deleteAuxArray(handle)
  }
}
