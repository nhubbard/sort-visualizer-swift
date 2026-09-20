import AlgorithmKit
import SortEngineKit

/*
MIT License
Copyright (c) 2021 aphitorite
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// ArrayV's partition-and-library hybrid. Equal-valued gap selection uses a reproducible
/// input-seeded generator in place of Java's fresh Random, so an input always records one tape.
public struct FlanSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "flansort")
  public let metadata = AlgorithmMetadata(
    displayName: "Flan Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1517, coefficients: [239916, 264.722, 0.0699525],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0699525, 52.4862, -686.182], rSquared: 0.999933),
    implementationComplexity: 102,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(1)", iconName: "square.stack.3d.up"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let gap = 14, ratio = 4
    let paHandle = engine.createAuxArray(length: gap + 2)
    let heapHandle = engine.createAuxArray(length: gap + 2)
    var pa = [Int](repeating: 0, count: gap + 2)
    var heap = [Int](repeating: 0, count: gap + 2)
    func writePA(_ i: Int, _ value: Int) { pa[i] = value; engine.writeAux(paHandle, at: i, value: value) }
    var randomState: UInt64 = 0x9e3779b97f4a7c15
    for value in engine.readAllValues() { randomState = (randomState ^ UInt64(bitPattern: Int64(value))) &* 0xbf58476d1ce4e5b9 &+ 0x94d049bb133111eb }
    func randomChoice(_ count: Int) -> Int {
      randomState ^= randomState >> 12
      randomState ^= randomState << 25
      randomState ^= randomState >> 27
      return Int((randomState &* 0x2545f4914f6cdd1d) % UInt64(count))
    }
    func median(_ a: Int, _ m: Int, _ b: Int) -> Int {
      if engine.compare(m, a, by: >) {
        if engine.compare(m, b, by: <) { return m }
        return engine.compare(a, b, by: >) ? a : b
      }
      if engine.compare(m, b, by: >) { return m }
      return engine.compare(a, b, by: <) ? a : b
    }
    func ninther(_ a: Int, _ b: Int) -> Int {
      let s = (b - a) / 9
      let a1 = median(a, a + s, a + 2 * s)
      let m1 = median(a + 3 * s, a + 4 * s, a + 5 * s)
      let b1 = median(a + 6 * s, a + 7 * s, a + 8 * s)
      return median(a1, m1, b1)
    }
    func pivotIndex(_ a: Int, _ b: Int) -> Int {
      let s = (b - a) / 3
      return median(ninther(a, a + s), ninther(a + s, a + 2 * s), ninther(a + 2 * s, b))
    }
    func binSearch(_ a: Int, _ b: Int, _ val: Int, backward: Bool) -> Int {
      var a = a, b = b
      while a < b {
        let m = a + (b - a) / 2
        let matches = backward ? engine.compareValue(m, against: val, by: <) : engine.compareValue(m, against: val, by: >)
        if matches { b = m } else { a = m + 1 }
      }
      return a
    }
    func insertTo(_ value: Int, _ start: Int, _ end: Int) {
      var i = start
      while i > end {
        i -= 1
        engine.setValue(i + 1, engine.readValue(at: i))
      }
      engine.setValue(end, value)
    }
    func binaryInsertion(_ a: Int, _ b: Int) {
      guard b > a + 1 else { return }
      for i in (a + 1)..<b {
        let value = engine.readValue(at: i)
        insertTo(value, i, binSearch(a, i, value, backward: false))
      }
    }
    func blockSearch(_ a: Int, _ b: Int, _ val: Int, right: Bool) -> Int {
      var a = a, b = b
      while a < b {
        let m = a + (((b - a) / (gap + 1)) / 2) * (gap + 1)
        let found = engine.compareValue(m, against: val, by: right ? (>) : (>=))
        if found { b = m } else { a = m + gap + 1 }
      }
      return a
    }
    func retrieve(_ i: Int, _ p: Int, _ pEnd: Int, _ bsv: Int, backward: Bool) {
      var j = i - 1
      var k = pEnd - (gap + 1)
      while k > p + gap {
        var m = binSearch(k - gap, k, bsv, backward: backward) - 1
        k -= gap + 1
        while m >= k { engine.swap(j, m); j -= 1; m -= 1 }
      }
      var m = binSearch(p, p + gap, bsv, backward: backward) - 1
      while m >= p { engine.swap(j, m); j -= 1; m -= 1 }
    }
    func librarySort(_ a: Int, _ b: Int, _ p: Int, _ bsv: Int, backward: Bool) {
      let len = b - a
      if len < 32 { binaryInsertion(a, b); return }
      var s = len
      while s >= 32 { s = (s - 1) / ratio + 1 }
      var i = a + s, j = a + ratio * s, pEnd = p + (s + 1) * (gap + 1) + gap
      binaryInsertion(a, i)
      for k in 0..<s { engine.swap(a + k, p + k * (gap + 1) + gap) }
      while i < b {
        if i == j {
          retrieve(i, p, pEnd, bsv, backward: backward)
          s = i - a
          pEnd = p + (s + 1) * (gap + 1) + gap
          j = a + (j - a) * ratio
          for k in 0..<s { engine.swap(a + k, p + k * (gap + 1) + gap) }
        }
        let value = engine.readValue(at: i)
        var bLoc = blockSearch(p + gap, pEnd - (gap + 1), value, right: false)
        if engine.compareValue(bLoc, against: value, by: ==) {
          let eqEnd = blockSearch(bLoc + gap + 1, pEnd - (gap + 1), value, right: true)
          bLoc += randomChoice((eqEnd - bLoc) / (gap + 1)) * (gap + 1)
        }
        let loc = binSearch(bLoc - gap, bLoc, bsv, backward: backward)
        if loc == bLoc {
          repeat { bLoc += gap + 1 }
            while bLoc < pEnd && binSearch(bLoc - gap, bLoc, bsv, backward: backward) == bLoc
          if bLoc == pEnd {
            retrieve(i, p, pEnd, bsv, backward: backward)
            s = i - a
            pEnd = p + (s + 1) * (gap + 1) + gap
            j = a + (j - a) * ratio
            for k in 0..<s { engine.swap(a + k, p + k * (gap + 1) + gap) }
          } else {
            let rotP = binSearch(bLoc - gap, bLoc, bsv, backward: backward)
            let rotS = bLoc - max(rotP, bLoc - gap / 2)
            var m = bLoc - rotS, end = bLoc
            while m > loc - rotS { m -= 1; end -= 1; engine.swap(end, m) }
          }
        } else {
          let displaced = engine.readValue(at: loc)
          engine.setValue(i, displaced)
          i += 1
          insertTo(value, loc, binSearch(bLoc - gap, loc, value, backward: false))
        }
      }
      retrieve(b, p, pEnd, bsv, backward: backward)
    }
    func readPA(_ i: Int) -> Int { engine.markAuxRead(paHandle, at: i); return pa[i] }
    func kWayMerge(_ runLength: Int, _ b: Int, _ destination: Int, _ runCount: Int) {
      if runCount < 2 {
        if runCount == 1 {
          var p = destination
          while readPA(0) < b { engine.swap(p, pa[0]); p += 1; writePA(0, pa[0] + 1) }
        }
        return
      }
      let a = pa[0]
      for i in 0..<runCount { heap[i] = i; engine.writeAux(heapHandle, at: i, value: i) }
      func sift(_ item: Int, _ root: Int, _ size: Int) {
        MultiWayMergeSortingTemplate.siftDown(&engine, heap: &heap, heapHandle: heapHandle,
                                               positions: pa, positionsHandle: paHandle, item: item, root: root, size: size)
      }
      for i in stride(from: (runCount - 1) / 2, through: 0, by: -1) { sift(heap[i], i, runCount) }
      var size = runCount, p = destination
      while size > 0 {
        let run = heap[0]
        engine.swap(p, pa[run]); p += 1
        writePA(run, pa[run] + 1)
        if readPA(run) == min(a + (run + 1) * runLength, b) {
          size -= 1
          sift(heap[size], 0, size)
        } else { sift(heap[0], 0, size) }
      }
    }
    var a = 0, b = n
    while b - a >= 32 {
      let pivot = engine.readValue(at: pivotIndex(a, b))
      var i1 = a, i = a - 1, j = b, j1 = b
      while true {
        i += 1
        while i < j {
          if engine.compareValue(i, against: pivot, by: ==) { engine.swap(i1, i); i1 += 1 }
          else if engine.compareValue(i, against: pivot, by: <) { break }
          i += 1
        }
        j -= 1
        while j > i {
          if engine.compareValue(j, against: pivot, by: ==) { j1 -= 1; engine.swap(j1, j) }
          else if engine.compareValue(j, against: pivot, by: >) { break }
          j -= 1
        }
        if i < j { engine.swap(i, j) }
        else {
          if i1 == b { engine.deleteAuxArray(paHandle); engine.deleteAuxArray(heapHandle); return }
          if j < i { j += 1 }
          while i1 > a { i -= 1; i1 -= 1; engine.swap(i, i1) }
          while j1 < b { engine.swap(j, j1); j += 1; j1 += 1 }
          break
        }
      }
      var left = i - a, right = b - j, m: Int, runCount = 0
      if left <= right {
        m = b - left
        left = max((right + 1) / (gap + 1), 16)
        var k = a
        while k < i {
          librarySort(k, min(k + left, i), j, pivot, backward: true)
          writePA(runCount, k); runCount += 1; k += left
        }
        kWayMerge(left, i, m, runCount)
        if j - i < m - j {
          while i < j { m -= 1; engine.swap(i, m); i += 1 }
          b = m
        } else {
          while m > j { m -= 1; engine.swap(i, m); i += 1 }
          b = i
        }
      } else {
        m = a + right
        right = max((left + 1) / (gap + 1), 16)
        var k = j
        while k < b {
          librarySort(k, min(k + right, b), a, pivot, backward: false)
          writePA(runCount, k); runCount += 1; k += right
        }
        kWayMerge(right, b, a, runCount)
        if i - m < j - i {
          while m < i { j -= 1; engine.swap(m, j); m += 1 }
          a = j
        } else {
          while j > i { j -= 1; engine.swap(m, j); m += 1 }
          a = m
        }
      }
    }
    binaryInsertion(a, b)
    engine.deleteAuxArray(paHandle)
    engine.deleteAuxArray(heapHandle)
  }
}
