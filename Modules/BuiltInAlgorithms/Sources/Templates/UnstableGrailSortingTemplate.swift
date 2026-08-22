import SortEngineKit

/// Ported from ArrayV's `sorts/templates/UnstableGrailSorting` — Andrey Astrelin's classic
/// in-place block-merge sort, the *unstable* variant (no per-block original-stream tracking; see
/// `GrailSortingTemplate` for the stable version once that lands, which adds exactly that tracking
/// back in). Only one concrete algorithm (`UnstableGrailSort`) extends this template in ArrayV,
/// and it's a pure pass-through — the entire algorithm lives here, the concrete wrapper is a
/// one-line `commonSort` call.
enum UnstableGrailSortingTemplate {
  private static func multiSwap(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ count: Int) {
    for i in 0..<count {
      engine.swap(a + i, b + i)
    }
  }

  /// Repeated block-swap of the smaller side — a juggling-style, zero-extra-memory rotation.
  static func rotate(_ engine: inout RecordingEngine, _ pos: Int, _ lenA: Int, _ lenB: Int) {
    var pos = pos
    var lenA = lenA
    var lenB = lenB
    while lenA != 0 && lenB != 0 {
      if lenA <= lenB {
        multiSwap(&engine, pos, pos + lenA, lenA)
        pos += lenA
        lenB -= lenA
      } else {
        multiSwap(&engine, pos + (lenA - lenB), pos + lenA, lenB)
        lenA -= lenB
      }
    }
  }

  /// Base case for `len <= 16` — the same "backward-swapping insertion pass" shape as
  /// `OptimizedGnomeSort.swift`, scoped to `[pos, pos+len)` instead of the whole array (ArrayV
  /// delegates to a whole separate `OptimizedGnomeSort` instance for this; a small local insertion
  /// sort avoids that cross-algorithm coupling for an equivalent result).
  private static func insertSort(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    guard len > 1 else { return }
    for i in 1..<len {
      var p = pos + i
      while p > pos && engine.compare(p - 1, p, by: >) {
        engine.swap(p - 1, p)
        p -= 1
      }
    }
  }

  /// Direction-parameterized binary search: `isLeft` finds the first index with a value `>=`
  /// `array[keyPos]` (lower bound), `!isLeft` finds the first index with a value `>` (upper bound).
  private static func binSearch(
    _ engine: inout RecordingEngine, _ pos: Int, _ len: Int, _ keyPos: Int, _ isLeft: Bool
  ) -> Int {
    var left = -1
    var right = len
    while left < right - 1 {
      let mid = left + (right - left) / 2
      if isLeft {
        if engine.compare(pos + mid, keyPos, by: >=) {
          right = mid
        } else {
          left = mid
        }
      } else {
        if engine.compare(pos + mid, keyPos, by: >) {
          right = mid
        } else {
          left = mid
        }
      }
    }
    return right
  }

  /// Merges `[pos, pos+len1)` and `[pos+len1, pos+len1+len2)` (both already sorted) in place with
  /// zero extra memory — O(min(len1,len2)^2 + max(len1,len2)) via repeated binary-search + rotate.
  static func mergeWithoutBuffer(_ engine: inout RecordingEngine, _ pos: Int, _ len1: Int, _ len2: Int) {
    var pos = pos
    var len1 = len1
    var len2 = len2
    if len1 < len2 {
      while len1 != 0 {
        let loc = binSearch(&engine, pos + len1, len2, pos, true)
        if loc != 0 {
          rotate(&engine, pos, len1, loc)
          pos += loc
          len2 -= loc
        }
        if len2 == 0 { break }
        repeat {
          pos += 1
          len1 -= 1
        } while len1 != 0 && engine.compare(pos, pos + len1, by: <=)
      }
    } else {
      while len2 != 0 {
        let loc = binSearch(&engine, pos, len1, pos + (len1 + len2 - 1), false)
        if loc != len1 {
          rotate(&engine, pos + loc, len1 - loc, len2)
          len1 = loc
        }
        if len1 == 0 { break }
        repeat {
          len2 -= 1
        } while len2 != 0 && engine.compare(pos + len1 - 1, pos + len1 + len2 - 1, by: <=)
      }
    }
  }

  /// `arr[dist..<pos]` is a free buffer; merges `[pos, pos+leftLen)` and `[pos+leftLen,
  /// pos+leftLen+rightLen)` (both sorted) INTO that buffer region via swaps.
  private static func mergeLeft(
    _ engine: inout RecordingEngine, _ pos: Int, _ leftLen: Int, _ rightLen: Int, _ dist: Int
  ) {
    var left = 0
    var right = leftLen
    var dist = dist
    let rightEnd = rightLen + leftLen
    while right < rightEnd {
      if left == leftLen || engine.compare(pos + left, pos + right, by: >) {
        engine.swap(pos + dist, pos + right)
        dist += 1
        right += 1
      } else {
        engine.swap(pos + dist, pos + left)
        dist += 1
        left += 1
      }
    }
    if dist != left {
      multiSwap(&engine, pos + dist, pos + left, leftLen - left)
    }
  }

  /// Mirror of `mergeLeft`, merging from the tail ends backward into a buffer positioned after.
  private static func mergeRight(
    _ engine: inout RecordingEngine, _ pos: Int, _ leftLen: Int, _ rightLen: Int, _ dist: Int
  ) {
    var mergedPos = leftLen + rightLen + dist - 1
    var right = leftLen + rightLen - 1
    var left = leftLen - 1
    while left >= 0 {
      if right < leftLen || engine.compare(pos + left, pos + right, by: >) {
        engine.swap(pos + mergedPos, pos + left)
        mergedPos -= 1
        left -= 1
      } else {
        engine.swap(pos + mergedPos, pos + right)
        mergedPos -= 1
        right -= 1
      }
    }
    if right != mergedPos {
      while right >= leftLen {
        engine.swap(pos + mergedPos, pos + right)
        mergedPos -= 1
        right -= 1
      }
    }
  }

  /// Merges a "leftover" fragment of length `leftOverLen` with the next regular block of length
  /// `blockLen`, using the `blockLen`-sized region immediately before `pos` as a buffer (via
  /// swaps, so the buffer's old contents end up wherever they sorted to). Returns the new leftover
  /// length to carry into the next call in the chain.
  private static func smartMergeWithBuffer(
    _ engine: inout RecordingEngine, _ pos: Int, _ leftOverLen: Int, _ blockLen: Int
  ) -> Int {
    var dist = -blockLen
    var left = 0
    var right = leftOverLen
    var leftEnd = right
    var rightEnd = right + blockLen

    while left < leftEnd && right < rightEnd {
      if engine.compare(pos + left, pos + right, by: <=) {
        engine.swap(pos + dist, pos + left)
        dist += 1
        left += 1
      } else {
        engine.swap(pos + dist, pos + right)
        dist += 1
        right += 1
      }
    }

    let length: Int
    if left < leftEnd {
      length = leftEnd - left
      while left < leftEnd {
        leftEnd -= 1
        rightEnd -= 1
        engine.swap(pos + leftEnd, pos + rightEnd)
      }
    } else {
      length = rightEnd - right
    }
    return length
  }

  private static func mergeBuffersLeft(
    _ engine: inout RecordingEngine, _ pos: Int, _ blockCount: Int, _ blockLen: Int,
    _ aBlockCount: Int, _ lastLen: Int
  ) {
    if blockCount == 0 {
      let aBlocksLen = aBlockCount * blockLen
      mergeLeft(&engine, pos, aBlocksLen, lastLen, -blockLen)
      return
    }

    var leftOverLen = blockLen
    var processIndex = blockLen
    var restToProcess = 0

    for _ in 1..<blockCount {
      restToProcess = processIndex - leftOverLen
      leftOverLen = smartMergeWithBuffer(&engine, pos + restToProcess, leftOverLen, blockLen)
      processIndex += blockLen
    }
    restToProcess = processIndex - leftOverLen

    if lastLen != 0 {
      leftOverLen += blockLen * aBlockCount
      mergeLeft(&engine, pos + restToProcess, leftOverLen, lastLen, -blockLen)
    } else {
      multiSwap(&engine, pos + restToProcess, pos + (restToProcess - blockLen), leftOverLen)
    }
  }

  /// Bottom-up run construction: pairwise-sorts adjacent elements with a 4-slot shuffle trick,
  /// then doubles block size via `mergeLeft`/`rotate` until `buildLen` is reached.
  private static func buildBlocks(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int, _ buildLen: Int) {
    var pos = pos
    var dist = 1
    while dist < len {
      let extraDist = engine.compare(pos + dist - 1, pos + dist, by: >) ? 1 : 0
      engine.swap(pos + dist - 3, pos + dist - 1 + extraDist)
      engine.swap(pos + dist - 2, pos + dist - extraDist)
      dist += 2
    }
    if len % 2 != 0 {
      engine.swap(pos + len - 1, pos + len - 3)
    }
    pos -= 2
    var part = 2

    while part < buildLen {
      var left = 0
      let right = len - 2 * part
      while left <= right {
        mergeLeft(&engine, pos + left, part, part, -part)
        left += 2 * part
      }
      let rest = len - left
      if rest > part {
        mergeLeft(&engine, pos + left, part, rest - part, -part)
      } else {
        rotate(&engine, pos + left - part, part, rest)
      }
      pos -= part
      part *= 2
    }

    let restToBuild = len % (2 * buildLen)
    var leftOverPos = len - restToBuild

    if restToBuild <= buildLen {
      rotate(&engine, pos + leftOverPos, restToBuild, buildLen)
    } else {
      mergeRight(&engine, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen)
    }

    while leftOverPos > 0 {
      leftOverPos -= 2 * buildLen
      mergeRight(&engine, pos + leftOverPos, buildLen, buildLen, buildLen)
    }
  }

  /// Combines pairs of `buildLen`-sized super-blocks: within each `2*buildLen`-sized super-block,
  /// selection-sorts the `regBlockLen`-sized sub-blocks by their (first, last) element pair — no
  /// original-index tie-break, which is exactly what makes this variant unstable — then merges via
  /// `mergeBuffersLeft`.
  private static func combineBlocks(
    _ engine: inout RecordingEngine, _ pos: Int, _ len: Int, _ buildLen: Int, _ regBlockLen: Int
  ) {
    let combineLen = len / (2 * buildLen)
    var len = len
    var leftOver = len % (2 * buildLen)
    if leftOver <= buildLen {
      len -= leftOver
      leftOver = 0
    }

    for i in 0...combineLen {
      if i == combineLen && leftOver == 0 { break }

      let blockPos = pos + i * 2 * buildLen
      let blockCount = (i == combineLen ? leftOver : 2 * buildLen) / regBlockLen

      // `blockCount` is never 0 here: non-final super-blocks always have `blockCount ==
      // 2*buildLen/regBlockLen >= 4` once `buildLen` has doubled past `regBlockLen`, and the
      // final super-block's `leftOver` (when nonzero) is always `> buildLen`, itself a positive
      // multiple of `regBlockLen`, guaranteeing `leftOver / regBlockLen >= 1`.
      for index in 1..<blockCount {
        var leftIndex = index - 1
        for rightIndex in index..<blockCount {
          let leftHead = blockPos + leftIndex * regBlockLen
          let rightHead = blockPos + rightIndex * regBlockLen
          let rightComp = engine.compare(leftHead, rightHead, by: >)
          let tied = !rightComp && engine.values[leftHead] == engine.values[rightHead]
          let leftTail = blockPos + (leftIndex + 1) * regBlockLen - 1
          let rightTail = blockPos + (rightIndex + 1) * regBlockLen - 1
          if rightComp || (tied && engine.compare(leftTail, rightTail, by: >)) {
            leftIndex = rightIndex
          }
        }
        if leftIndex != index - 1 {
          multiSwap(&engine, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
        }
      }

      var aBlockCount = 0
      let lastLen = (i == combineLen) ? (leftOver % regBlockLen) : 0

      if lastLen != 0 {
        while aBlockCount < blockCount
          && engine.compare(
            blockPos + blockCount * regBlockLen,
            blockPos + (blockCount - aBlockCount - 1) * regBlockLen, by: <) {
          aBlockCount += 1
        }
      }
      mergeBuffersLeft(&engine, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen)
    }

    var remaining = len
    while remaining > 0 {
      remaining -= 1
      engine.swap(pos + remaining, pos + remaining - regBlockLen)
    }
  }

  /// Top-level entry point.
  static func commonSort(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    if len <= 16 {
      insertSort(&engine, pos, len)
      return
    }

    var blockLen = 1
    while blockLen * blockLen < len { blockLen *= 2 }
    var buildLen = blockLen

    buildBlocks(&engine, pos + blockLen, len - blockLen, buildLen)

    while len - blockLen > (buildLen * 2) {
      buildLen *= 2
      combineBlocks(&engine, pos + blockLen, len - blockLen, buildLen, blockLen)
    }

    insertSort(&engine, pos, blockLen)
    mergeWithoutBuffer(&engine, pos, blockLen, len - blockLen)
  }
}
