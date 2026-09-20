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

/// Cube-root block sizing followed by stable table sorts and a multiway merge. The merge first
/// saves one block in auxiliary memory, then fills vacated locations and restores the displaced
/// blocks by permutation cycles. Run number breaks ties in the shared heap.
public struct RemiSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "remisort")
  public let metadata = AlgorithmMetadata(
    displayName: "Remi Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1597, coefficients: [214423, 152.691, 0.00578722],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [17.984, 1.00164], rSquared: 0.999761),
    implementationComplexity: 82,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n^(2/3))", iconName: "square.stack.3d.up"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    func ceilCbrt(_ value: Int) -> Int {
      var a = 0, b = min(1291, value)
      while a < b {
        let m = (a + b) / 2
        if m * m * m >= value { b = m } else { a = m + 1 }
      }
      return a
    }
    let bLen = ceilCbrt(n), rLen = bLen * bLen, rCnt = (n - 1) / rLen + 1
    let keysHandle = engine.createAuxArray(length: rCnt < 2 ? n : rLen)
    var keys = Array(0..<(rCnt < 2 ? n : rLen))
    for i in keys.indices { engine.writeAux(keysHandle, at: i, value: i) }
    func writeKeys(_ index: Int, _ value: Int) {
      keys[index] = value
      engine.writeAux(keysHandle, at: index, value: value)
    }
    func readKeys(_ index: Int) -> Int { engine.markAuxRead(keysHandle, at: index); return keys[index] }
    func keyGreater(_ a: Int, _ b: Int, base: Int) -> Bool {
      var comparison = 0
      _ = engine.compare(base + a, base + b, by: { left, right in
        comparison = left < right ? -1 : (left > right ? 1 : 0)
        return comparison > 0
      })
      return comparison > 0 || (comparison == 0 && a > b)
    }
    func tableSift(_ root: Int, _ len: Int, _ base: Int, _ item: Int) {
      var j = root
      while 2 * j + 1 < len {
        j = 2 * j + 1
        if j + 1 < len && keyGreater(readKeys(j + 1), readKeys(j), base: base) { j += 1 }
      }
      while j > root && keyGreater(item, readKeys(j), base: base) { j = (j - 1) / 2 }
      var item = item
      while j > root {
        let old = readKeys(j)
        writeKeys(j, item)
        item = old
        j = (j - 1) / 2
      }
      writeKeys(root, item)
    }
    func tableSort(_ a: Int, _ b: Int) {
      let len = b - a
      guard len > 1 else { return }
      for i in stride(from: (len - 1) / 2, through: 0, by: -1) { tableSift(i, len, a, readKeys(i)) }
      for i in stride(from: len - 1, to: 0, by: -1) {
        let t = readKeys(i)
        writeKeys(i, readKeys(0))
        tableSift(0, i, a, t)
      }
      for i in 0..<len where readKeys(i) != i {
        let t = engine.readValue(at: a + i)
        var j = i, next = readKeys(i)
        repeat {
          engine.setValue(a + j, engine.readValue(at: a + next))
          writeKeys(j, j)
          j = next
          next = readKeys(next)
        } while next != i
        engine.setValue(a + j, t)
        writeKeys(j, j)
      }
    }
    if rCnt < 2 {
      tableSort(0, n)
      engine.deleteAuxArray(keysHandle)
      return
    }
    let bufHandle = engine.createAuxArray(length: rLen)
    let heapHandle = engine.createAuxArray(length: rCnt)
    let pHandle = engine.createAuxArray(length: rCnt)
    let paHandle = engine.createAuxArray(length: rCnt)
    var buf = [Int](repeating: 0, count: rLen)
    var heap = [Int](repeating: 0, count: rCnt)
    var p = [Int](repeating: 0, count: rCnt)
    var pa = [Int](repeating: 0, count: rCnt)
    func writeBuf(_ index: Int, _ value: Int) { buf[index] = value; engine.writeAux(bufHandle, at: index, value: value) }
    func writeP(_ index: Int, _ value: Int) { p[index] = value; engine.writeAux(pHandle, at: index, value: value) }
    func writePA(_ index: Int, _ value: Int) { pa[index] = value; engine.writeAux(paHandle, at: index, value: value) }
    func readP(_ index: Int) -> Int { engine.markAuxRead(pHandle, at: index); return p[index] }
    func readPA(_ index: Int) -> Int { engine.markAuxRead(paHandle, at: index); return pa[index] }
    func sift(_ item: Int, _ root: Int, _ size: Int) {
      MultiWayMergeSortingTemplate.siftDown(&engine, heap: &heap, heapHandle: heapHandle,
                                             positions: pa, positionsHandle: paHandle, item: item, root: root, size: size)
    }
    for run in 0..<rCnt {
      let start = run * rLen
      tableSort(start, min(start + rLen, n))
      writePA(run, start)
      writeP(run, start)
    }
    for i in 0..<rCnt { heap[i] = i; engine.writeAux(heapHandle, at: i, value: i) }
    for i in stride(from: (rCnt - 1) / 2, through: 0, by: -1) { sift(heap[i], i, rCnt) }
    var size = rCnt
    func advance(_ run: Int) {
      writePA(run, pa[run] + 1)
      if readPA(run) == min((run + 1) * rLen, n) {
        size -= 1
        sift(heap[size], 0, size)
      } else { sift(heap[0], 0, size) }
    }
    for i in 0..<rLen {
      let run = heap[0]
      writeBuf(i, engine.readValue(at: pa[run]))
      advance(run)
    }
    var t = 0, count = 0, c = 0
    while readPA(c) - readP(c) < bLen { c += 1 }
    repeat {
      let run = heap[0]
      engine.setValue(p[c], engine.readValue(at: pa[run]))
      writePA(run, pa[run] + 1)
      writeP(c, p[c] + 1)
      if readPA(run) == min((run + 1) * rLen, n) {
        size -= 1
        sift(heap[size], 0, size)
      } else { sift(heap[0], 0, size) }
      count += 1
      if count == bLen {
        writeKeys(t, c > 0 ? p[c] / bLen - bLen - 1 : -1)
        t += 1
        c = 0; count = 0
        while readPA(c) - readP(c) < bLen { c += 1 }
      }
    } while size > 0
    var end = n
    while count > 0 {
      count -= 1
      writeP(c, p[c] - 1)
      end -= 1
      engine.setValue(end, engine.readValue(at: p[c]))
    }
    writePA(rCnt - 1, end)
    writeKeys(keys.count - 1, -1)
    t = 0
    while readKeys(t) != -1 { t += 1 }
    var j = 0
    for i in 1..<rCnt {
      if j >= readP(0) { break }
      while readP(i) < readPA(i) {
        writeKeys(t, p[i] / bLen - bLen)
        t += 1
        while readKeys(t) != -1 { t += 1 }
        for x in 0..<bLen { engine.setValue(p[i] + x, engine.readValue(at: j + x)) }
        writeP(i, p[i] + bLen)
        j += bLen
      }
    }
    for x in 0..<rLen { engine.setValue(x, buf[x]) }
    let a1 = rLen
    let blockCount = (end - a1) / bLen
    for i in 0..<blockCount where readKeys(i) != i {
      for x in 0..<bLen { writeBuf(x, engine.readValue(at: a1 + i * bLen + x)) }
      var j = i, next = readKeys(i)
      repeat {
        for x in 0..<bLen { engine.setValue(a1 + j * bLen + x, engine.readValue(at: a1 + next * bLen + x)) }
        writeKeys(j, j)
        j = next
        next = readKeys(next)
      } while next != i
      for x in 0..<bLen { engine.setValue(a1 + j * bLen + x, buf[x]) }
      writeKeys(j, j)
    }
    engine.deleteAuxArray(keysHandle)
    engine.deleteAuxArray(bufHandle)
    engine.deleteAuxArray(heapHandle)
    engine.deleteAuxArray(pHandle)
    engine.deleteAuxArray(paHandle)
  }
}
