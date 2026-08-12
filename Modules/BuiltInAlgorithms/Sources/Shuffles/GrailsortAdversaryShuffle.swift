import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.GRAIL_BAD`, plus its two shared top-of-enum helpers `sort` (a
/// counting sort restricted to a subrange) and `shuffle` (a forward Fisher–Yates restricted to a
/// subrange — `RandomShuffle.swift` already has the backward-direction version, this is its
/// mirror). Below 17 elements this is just a full reversal; above that, it randomly shuffles the
/// whole array, counting-sorts a block of "keys" at the front plus a trailing remainder, reverses
/// the keys block, and finally pushes the keys through the remainder via a recursive
/// rotate/block-swap scheme (`push`/`rotate`/`multiSwap`) — the same block-rearrangement shape
/// GrailSort's own key-relocation step uses, repurposed here to construct GrailSort's worst case
/// rather than to sort.
public struct GrailsortAdversaryShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "grailbad")
  public let metadata = ShuffleMetadata(displayName: "Grailsort Adversary")
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    if n <= 16 {
      engine.reversal(0, n - 1)
      return
    }

    var blockLen = 1
    while blockLen * blockLen < n { blockLen *= 2 }

    let numKeys = (n - 1) / blockLen + 1
    let keys = blockLen + numKeys

    forwardShuffle(&engine, 0, n)
    countingSort(&engine, 0, keys)
    engine.reversal(0, keys - 1)
    countingSort(&engine, keys, n)

    push(&engine, keys, n, blockLen)
  }

  private func forwardShuffle(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    for i in start..<end {
      let randomIndex = Int.random(in: i..<end)
      engine.swap(i, randomIndex)
    }
  }

  private func countingSort(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard end > start else { return }
    var minValue = engine.values[start]
    var maxValue = minValue
    for i in (start + 1)..<end {
      let v = engine.values[i]
      if v < minValue { minValue = v } else if v > maxValue { maxValue = v }
    }

    let size = maxValue - minValue + 1
    var holes = [Int](repeating: 0, count: size)
    for i in start..<end {
      holes[engine.values[i] - minValue] += 1
    }

    var j = start
    for i in 0..<size {
      while holes[i] > 0 {
        holes[i] -= 1
        engine.setValue(j, i + minValue)
        j += 1
      }
    }
  }

  private func rotate(_ engine: inout RecordingEngine, _ a: Int, _ m: Int, _ b: Int) {
    engine.reversal(a, m - 1)
    engine.reversal(m, b - 1)
    engine.reversal(a, b - 1)
  }

  private func multiSwap(_ engine: inout RecordingEngine, _ pos: Int, _ to: Int) {
    if to > pos {
      var i = pos
      while i < to {
        engine.swap(i, i + 1)
        i += 1
      }
    } else {
      var i = pos
      while i > to {
        engine.swap(i, i - 1)
        i -= 1
      }
    }
  }

  private func push(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ bLen: Int) {
    let len = b - a
    let b1 = b - len % bLen
    let len1 = b1 - a
    guard len1 > 2 * bLen else { return }

    var m = bLen
    while 2 * m < len { m *= 2 }
    m += a

    if b1 - m < bLen {
      push(&engine, a, m, bLen)
    } else {
      m = a + b1 - m
      rotate(&engine, m - (bLen - 2), b1 - (bLen - 1), b1)
      multiSwap(&engine, a, m)
      rotate(&engine, a, m, b1)
      m = a + b1 - m

      push(&engine, a, m, bLen)
      push(&engine, m, b, bLen)
    }
  }
}
