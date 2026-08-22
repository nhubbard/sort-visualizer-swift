import SortEngineKit

/// Ported from ArrayV's `sorts/templates/GrailSorting` — Andrey Astrelin's classic in-place
/// block-merge sort, the *stable* variant (contrast with `UnstableGrailSortingTemplate`, which
/// this shares most of its shape with, minus the key-array/stream-fragment tracking that makes
/// this one stable). Confirmed genuine reuse across all 4 concrete subclasses in ArrayV
/// (`BlockInsertionSort`, `LazyStableSort`, `GrailSort`, `OptimizedLazyStableSort`) — every one
/// either calls inherited methods verbatim or overrides exactly one method while still leaning on
/// the rest (see Documentation/docs/reference/port-status.md's note on the Grail cluster).
///
/// **Two simplifications versus ArrayV's own template**, both because every concrete algorithm in
/// this codebase runs `commonSort` in pure in-place mode (no external scratch array is plumbed
/// through `SortAlgorithm`, matching how `GrailSort.swift` picks in-place over ArrayV's other two
/// user-selectable buffer modes):
/// 1. ArrayV's own "XBuf" method family (`grailSmartMergeWithXBuf`/`grailMergeLeftWithXBuf`/
///    `grailMergeBuffersLeftWithXBuf`) only ever runs when a real external buffer is supplied.
///    With no external buffer, `grailBuildBlocks`'s own `buildBuf = min(buildLen, extBufLen)`
///    always evaluates to `0`, so ArrayV's own code provably never takes that branch either in
///    this configuration — the XBuf family is dead code for an in-place caller, not just unused,
///    so it isn't ported here at all.
/// 2. With the XBuf branch gone, `buildBlocks`'s remaining logic is textually identical to
///    `UnstableGrailSortingTemplate.buildBlocks` (confirmed by direct comparison of both Java
///    sources) — reused verbatim below rather than re-transcribed and re-verified from scratch.
/// `grailInPlaceMergeSort`/`grailInPlaceMerge` are additionally skipped: confirmed dead code in
/// ArrayV itself (no caller anywhere in its own source tree), unrelated to the in-place-mode
/// simplifications above.
enum GrailSortingTemplate {
  private static func multiSwap(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ count: Int) {
    for i in 0..<count {
      engine.swap(a + i, b + i)
    }
  }

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

  /// Base case for `len <= 16` — see `UnstableGrailSortingTemplate.insertSort`'s doc comment for
  /// why this is a small local insertion sort rather than a call into another shipped algorithm.
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

  /// Scans forward collecting up to `numKeys` DISTINCT values, rotating each newly-found distinct
  /// value into a growing sorted "key" region at the very front of `[pos, pos+len)`. Returns how
  /// many distinct keys were actually found (may be `< numKeys` if there aren't enough distinct
  /// values in the range). Cost: `2*len + numKeys^2/2`.
  private static func findKeys(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int, _ numKeys: Int)
    -> Int {
    var dist = 1
    var foundKeys = 1
    var firstKey = 0

    while dist < len && foundKeys < numKeys {
      let loc = binSearch(&engine, pos + firstKey, foundKeys, pos + dist, true)
      if loc == foundKeys || engine.values[pos + dist] != engine.values[pos + (firstKey + loc)] {
        rotate(&engine, pos + firstKey, foundKeys, dist - (firstKey + foundKeys))
        firstKey = dist - foundKeys
        rotate(&engine, pos + (firstKey + loc), foundKeys - loc, 1)
        foundKeys += 1
      }
      dist += 1
    }
    rotate(&engine, pos, firstKey, foundKeys)
    return foundKeys
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

  /// Returns `(newLeftOverLength, newLeftOverFragment)`. `fragment` tracks which "stream" (0 or 1,
  /// relative to the block-combine's `midkey` split) the leftover run currently belongs to — this
  /// bookkeeping is the whole reason this variant is stable where `UnstableGrailSortingTemplate`
  /// isn't: it lets ties resolve by original stream membership instead of raw value alone.
  private static func smartMergeWithoutBuffer(
    _ engine: inout RecordingEngine, _ pos: Int, _ leftOverLen: Int, _ leftOverFrag: Int,
    _ regBlockLen: Int
  ) -> (length: Int, fragment: Int) {
    guard regBlockLen != 0 else { return (leftOverLen, leftOverFrag) }

    var pos = pos
    var len1 = leftOverLen
    var len2 = regBlockLen
    let typeFrag = 1 - leftOverFrag

    // Matches ArrayV's own `Reads.compareValues(a, b) - typeFrag` exactly: a 3-way compare
    // (-1/0/1) with `typeFrag` (0 or 1) subtracted, so the `>= 0` / `< 0` checks below flip
    // which direction counts as "in order" depending on which stream fragment is inverted.
    func compareValue(_ a: Int, _ b: Int) -> Int {
      if engine.values[a] < engine.values[b] { return -1 }
      if engine.values[a] > engine.values[b] { return 1 }
      return 0
    }

    if len1 != 0 && compareValue(pos + len1 - 1, pos + len1) - typeFrag >= 0 {
      while len1 != 0 {
        let foundLen = binSearch(&engine, pos + len1, len2, pos, typeFrag != 0)
        if foundLen != 0 {
          rotate(&engine, pos, len1, foundLen)
          pos += foundLen
          len2 -= foundLen
        }
        if len2 == 0 { return (len1, leftOverFrag) }
        repeat {
          pos += 1
          len1 -= 1
        } while len1 != 0 && compareValue(pos, pos + len1) - typeFrag < 0
      }
    }
    return (len2, typeFrag)
  }

  private static func smartMergeWithBuffer(
    _ engine: inout RecordingEngine, _ pos: Int, _ leftOverLen: Int, _ leftOverFrag: Int,
    _ blockLen: Int
  ) -> (length: Int, fragment: Int) {
    var dist = -blockLen
    var left = 0
    var right = leftOverLen
    var leftEnd = right
    var rightEnd = right + blockLen
    let typeFrag = 1 - leftOverFrag

    func compareValue(_ a: Int, _ b: Int) -> Int {
      if engine.values[a] < engine.values[b] { return -1 }
      if engine.values[a] > engine.values[b] { return 1 }
      return 0
    }

    while left < leftEnd && right < rightEnd {
      if compareValue(pos + left, pos + right) - typeFrag < 0 {
        engine.swap(pos + dist, pos + left)
        dist += 1
        left += 1
      } else {
        engine.swap(pos + dist, pos + right)
        dist += 1
        right += 1
      }
    }

    var fragment = leftOverFrag
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
      fragment = typeFrag
    }
    return (length, fragment)
  }

  /// Drives a whole chain of `smartMergeWithBuffer`/`smartMergeWithoutBuffer` calls across
  /// `blockCount` regular blocks (tagged by `keysPos`/`midkey`) plus their trailing irregular
  /// block, matching `array[keysPos+i] < array[midkey]` to decide which "stream" block `i` came
  /// from.
  private static func mergeBuffersLeft(
    _ engine: inout RecordingEngine, _ keysPos: Int, _ midkey: Int, _ pos: Int, _ blockCount: Int,
    _ blockLen: Int, _ havebuf: Bool, _ aBlockCount: Int, _ lastLen: Int
  ) {
    if blockCount == 0 {
      let aBlocksLen = aBlockCount * blockLen
      if havebuf {
        mergeLeft(&engine, pos, aBlocksLen, lastLen, -blockLen)
      } else {
        mergeWithoutBuffer(&engine, pos, aBlocksLen, lastLen)
      }
      return
    }

    var leftOverLen = blockLen
    var leftOverFrag = engine.values[keysPos] < engine.values[midkey] ? 0 : 1
    var processIndex = blockLen
    var restToProcess = 0

    for keyIndex in 1..<blockCount {
      restToProcess = processIndex - leftOverLen
      let nextFrag = engine.values[keysPos + keyIndex] < engine.values[midkey] ? 0 : 1

      if nextFrag == leftOverFrag {
        if havebuf {
          multiSwap(&engine, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
        }
        restToProcess = processIndex
        leftOverLen = blockLen
      } else {
        let result: (length: Int, fragment: Int)
        if havebuf {
          result = smartMergeWithBuffer(&engine, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
        } else {
          result = smartMergeWithoutBuffer(&engine, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
        }
        leftOverLen = result.length
        leftOverFrag = result.fragment
      }
      processIndex += blockLen
    }
    restToProcess = processIndex - leftOverLen

    if lastLen != 0 {
      if leftOverFrag != 0 {
        if havebuf {
          multiSwap(&engine, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
        }
        restToProcess = processIndex
        leftOverLen = blockLen * aBlockCount
        leftOverFrag = 0
      } else {
        leftOverLen += blockLen * aBlockCount
      }
      if havebuf {
        mergeLeft(&engine, pos + restToProcess, leftOverLen, lastLen, -blockLen)
      } else {
        mergeWithoutBuffer(&engine, pos + restToProcess, leftOverLen, lastLen)
      }
    } else if havebuf {
      multiSwap(&engine, pos + restToProcess, pos + (restToProcess - blockLen), leftOverLen)
    }
  }

  /// Bottom-up run construction. Textually identical to
  /// `UnstableGrailSortingTemplate.buildBlocks` — see this file's own doc comment for why (no
  /// external buffer means ArrayV's own "XBuf" branch is provably unreachable here too).
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

  /// Combines pairs of `buildLen`-sized super-blocks. Unlike
  /// `UnstableGrailSortingTemplate.combineBlocks`, the selection sort here compares blocks via a
  /// separate KEY array (`keyPos`) tagged per block, tie-breaking on the key's own order (stable!)
  /// instead of each block's last element (unstable) — and tracks `midkey` (the stream-A/B split
  /// index into the key array) through every key swap via XOR, since the selection sort can move
  /// the very block `midkey` points at.
  private static func combineBlocks(
    _ engine: inout RecordingEngine, _ keyPos: Int, _ pos: Int, _ len: Int, _ buildLen: Int,
    _ regBlockLen: Int, _ havebuf: Bool
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

      insertSort(&engine, keyPos, blockCount + (i == combineLen ? 1 : 0))

      var midkey = buildLen / regBlockLen

      for index in 1..<blockCount {
        var leftIndex = index - 1
        for rightIndex in index..<blockCount {
          let leftHead = blockPos + leftIndex * regBlockLen
          let rightHead = blockPos + rightIndex * regBlockLen
          let rightComp = engine.compare(leftHead, rightHead, by: >)
          let tied = !rightComp && engine.values[leftHead] == engine.values[rightHead]
          if rightComp || (tied && engine.compare(keyPos + leftIndex, keyPos + rightIndex, by: >)) {
            leftIndex = rightIndex
          }
        }
        if leftIndex != index - 1 {
          multiSwap(&engine, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
          engine.swap(keyPos + (index - 1), keyPos + leftIndex)
          if midkey == index - 1 || midkey == leftIndex {
            midkey ^= (index - 1) ^ leftIndex
          }
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
      mergeBuffersLeft(
        &engine, keyPos, keyPos + midkey, blockPos, blockCount - aBlockCount, regBlockLen, havebuf,
        aBlockCount, lastLen)
    }

    if havebuf {
      var remaining = len
      while remaining > 0 {
        remaining -= 1
        engine.swap(pos + remaining, pos + remaining - regBlockLen)
      }
    }
  }

  /// Simple O(n log n) alternate path, independent of the block-merge machinery above: pairwise
  /// compare-swap, then doubling `mergeWithoutBuffer`. Used directly by `LazyStableSort`, and
  /// overridden entirely by `OptimizedLazyStableSort`.
  static func lazyStableSort(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    var dist = 1
    while dist < len {
      if engine.compare(pos + dist - 1, pos + dist, by: >) {
        engine.swap(pos + dist - 1, pos + dist)
      }
      dist += 2
    }

    var part = 2
    while part < len {
      var left = 0
      let right = len - 2 * part
      while left <= right {
        mergeWithoutBuffer(&engine, pos + left, part, part)
        left += 2 * part
      }
      let rest = len - left
      if rest > part {
        mergeWithoutBuffer(&engine, pos + left, part, rest - part)
      }
      part *= 2
    }
  }

  /// Top-level entry point (in-place mode only — see this file's own doc comment).
  static func commonSort(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    if len <= 16 {
      insertSort(&engine, pos, len)
      return
    }

    var blockLen = 1
    while blockLen * blockLen < len { blockLen *= 2 }

    var numKeys = (len - 1) / blockLen + 1
    let keysFound = findKeys(&engine, pos, len, numKeys + blockLen)

    var bufferEnabled = true
    var blockLen2 = blockLen

    if keysFound < numKeys + blockLen {
      if keysFound < 4 {
        lazyStableSort(&engine, pos, len)
        return
      }
      numKeys = blockLen
      while numKeys > keysFound { numKeys /= 2 }
      bufferEnabled = false
      blockLen2 = 0
    }

    let dist = blockLen2 + numKeys
    var buildLen = bufferEnabled ? blockLen2 : numKeys

    buildBlocks(&engine, pos + dist, len - dist, buildLen)

    // 2 * buildLen are built.
    while len - dist > (buildLen * 2) {
      buildLen *= 2
      var regBlockLen = blockLen2
      var buildBufEnabled = bufferEnabled

      if !bufferEnabled {
        if numKeys > 4 && numKeys / 8 * numKeys >= buildLen {
          regBlockLen = numKeys / 2
          buildBufEnabled = true
        } else {
          var calcKeys = 1
          var i = buildLen * keysFound / 2
          while calcKeys < numKeys && i != 0 {
            calcKeys *= 2
            i /= 8
          }
          regBlockLen = (2 * buildLen) / calcKeys
        }
      }
      combineBlocks(&engine, pos, pos + dist, len - dist, buildLen, regBlockLen, buildBufEnabled)
    }

    insertSort(&engine, pos, dist)
    mergeWithoutBuffer(&engine, pos, dist, len - dist)
  }
}
