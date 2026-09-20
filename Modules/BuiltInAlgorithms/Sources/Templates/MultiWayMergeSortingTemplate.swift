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

/// The shared run-head heap from ArrayV's MultiWayMergeSorting. Run number is the stable
/// tie-breaker; the two concrete sorts retain their own, different merge procedures.
enum MultiWayMergeSortingTemplate {
  static func keyLessThan(
    _ engine: inout RecordingEngine, positions: [Int], positionsHandle: AuxHandle, _ a: Int, _ b: Int
  ) -> Bool {
    engine.markAuxRead(positionsHandle, at: a)
    engine.markAuxRead(positionsHandle, at: b)
    let ai = positions[a], bi = positions[b]
    var comparison = 0
    _ = engine.compare(ai, bi, by: { left, right in
      comparison = left < right ? -1 : (left > right ? 1 : 0)
      return comparison < 0
    })
    return comparison < 0 || (comparison == 0 && a < b)
  }

  static func siftDown(
    _ engine: inout RecordingEngine, heap: inout [Int], heapHandle: AuxHandle,
    positions: [Int], positionsHandle: AuxHandle, item: Int, root: Int, size: Int
  ) {
    var root = root
    while 2 * root + 2 < size {
      let left = 2 * root + 1
      engine.markAuxRead(heapHandle, at: left)
      engine.markAuxRead(heapHandle, at: left + 1)
      let child = keyLessThan(&engine, positions: positions, positionsHandle: positionsHandle,
                              heap[left], heap[left + 1]) ? left : left + 1
      engine.markAuxRead(heapHandle, at: child)
      if keyLessThan(&engine, positions: positions, positionsHandle: positionsHandle, heap[child], item) {
        heap[root] = heap[child]
        engine.writeAux(heapHandle, at: root, value: heap[root])
        root = child
      } else { break }
    }
    let left = 2 * root + 1
    if left < size {
      engine.markAuxRead(heapHandle, at: left)
    }
    if left < size && keyLessThan(&engine, positions: positions, positionsHandle: positionsHandle,
                                  heap[left], item) {
      heap[root] = heap[left]
      engine.writeAux(heapHandle, at: root, value: heap[root])
      root = left
    }
    heap[root] = item
    engine.writeAux(heapHandle, at: root, value: item)
  }
}
