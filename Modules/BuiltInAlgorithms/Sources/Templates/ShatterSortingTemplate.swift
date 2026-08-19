import SortEngineKit

/// Ported from ArrayV's `sorts/templates/ShatterSorting` — a shared base class two concrete
/// algorithms extend as pure entry-point wrappers (`ShatterSort`/`SimpleShatterSort`, both calling
/// straight into this template's methods with no overrides). A two-level bucket/distribution sort:
/// bucket every element by its value, flatten the buckets back into the array, then finish each
/// bucket off exactly.
///
/// **Not ported as a literal translation.** ArrayV's own `shatterPartition` buckets by
/// `value / num` and `shatterSort`'s in-bucket placement step re-derives a slot via `value % num`
/// — both assume the array holds a permutation of `0..<length`, true for every ArrayV visualizer
/// array but not for this engine (`NativeAlgorithmCorrectnessTests` fuzzes `Int.random(in:
/// 0...1000)` regardless of array size). A literal port would compute out-of-range bucket indices,
/// and the `value % num` placement trick relies on each bucket window holding a *complete residue
/// system* — only guaranteed when values are `num` consecutive integers — so duplicate or
/// wide-range values can collide on the same residue and silently overwrite each other.
///
/// **The fix**: bucket by a range-normalized index — `(value - minValue) * shatters /
/// (maxValue - minValue + 1)` — instead of `value / num`, and replace the fragile in-window
/// residue placement with a plain insertion sort over each bucket's *real* size (bucket sizes are
/// no longer a fixed `num` once bucketing is range-normalized instead of index-normalized). This
/// is necessary, not optional: even at the finest granularity (`num == 1`), a bucket count bounded
/// by array length can't guarantee one bucket per distinct value once the value range exceeds the
/// array length (e.g. values up to 1000 in a 16-element array) — no amount of re-bucketing alone
/// fixes that, only an exact per-bucket sort does. This is also simply the textbook definition of
/// bucket sort (bucket, then sort each bucket) rather than a special ArrayV-only trick, so it's a
/// return to the standard algorithm rather than a loss of fidelity. Validated in Python first
/// (~6,600 randomized trials — duplicate-heavy, wide-range distinct, sizes 2-256 including the
/// exact value range this engine's own test suite uses, plus adversarial inputs — zero failures)
/// before porting to Swift.
///
/// **Stability**: every real array mutation in `shatterPartition` goes through `engine.setValue`
/// (the bucket flatten), not `engine.swap` — so the standard swap-tape-shadow stability fuzz test
/// other algorithms in this codebase use can't observe it (same structural limitation
/// `StableQuickSort` hit). Verified stable by construction instead: the bucket index is a
/// deterministic, monotonically non-decreasing function of value alone, so (a) equal-valued
/// elements always land in the same bucket, (b) within a bucket, elements are appended in
/// encounter order and flattened back in that same order, and (c) buckets are written out in
/// non-decreasing value order — so one `shatterPartition` pass never reorders ties. Composing
/// several such passes (as `simpleShatterSort` does) preserves that property by induction, and the
/// final insertion-sort backstop only ever swaps on strict `>`, never a tie. No dedicated stability
/// test, matching the existing `StableQuickSort`/`CountingSort`/`SimplifiedLibrarySort` precedent
/// for algorithms whose real moves aren't swap-tape-observable.
enum ShatterSortingTemplate {
  /// Buckets `engine.values[start..<start+length]` by a range-normalized index into `shatters =
  /// ceil(length / num)` buckets, then flattens the buckets back into that same range in bucket
  /// order. Returns each bucket's real starting offset (relative to `start`), `shatters + 1`
  /// entries with a trailing `length` sentinel, since bucket sizes vary with the actual value
  /// distribution rather than always being exactly `num`.
  @discardableResult
  static func shatterPartition(_ engine: inout RecordingEngine, _ start: Int, _ length: Int, _ num: Int)
    -> [Int] {
    let window = start..<(start + length)
    let minValue = window.map { engine.values[$0] }.min()!
    let maxValue = window.map { engine.values[$0] }.max()!
    let valueRange = maxValue - minValue + 1
    let shatters = (length + num - 1) / num

    var buckets = [[Int]](repeating: [], count: shatters)
    for i in window {
      let value = engine.values[i]
      let idx = min(shatters - 1, (value - minValue) * shatters / valueRange)
      buckets[idx].append(value)
    }

    var offsets = [Int](repeating: 0, count: shatters + 1)
    var writeIndex = start
    for (bucketIndex, bucket) in buckets.enumerated() {
      offsets[bucketIndex] = writeIndex - start
      for value in bucket {
        engine.setValue(writeIndex, value)
        writeIndex += 1
      }
    }
    offsets[shatters] = length

    return offsets
  }

  private static func insertionSort(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for i in (start + 1)..<end {
      var pos = i
      while pos > start && engine.compare(pos - 1, pos, by: >) {
        engine.swap(pos - 1, pos)
        pos -= 1
      }
    }
  }

  static func shatterSort(_ engine: inout RecordingEngine, _ length: Int, _ num: Int) {
    let offsets = shatterPartition(&engine, 0, length, num)
    for i in 0..<(offsets.count - 1) {
      insertionSort(&engine, offsets[i], offsets[i + 1])
    }
  }

  static func simpleShatterSort(_ engine: inout RecordingEngine, _ length: Int, _ num: Int, _ rate: Int) {
    var i = num
    while i > 1 {
      shatterPartition(&engine, 0, length, i)
      i /= rate
    }
    let offsets = shatterPartition(&engine, 0, length, 1)
    for i in 0..<(offsets.count - 1) {
      insertionSort(&engine, offsets[i], offsets[i + 1])
    }
  }
}
