import SortEngineKit

/// Ported from ArrayV's `sorts/templates/BinaryQuickSorting` — a shared base class two concrete
/// algorithms extend as pure entry-point wrappers (`BinaryQuickSortIterative`/
/// `BinaryQuickSortRecursive`, both calling straight into this template's methods with no
/// overrides). Binary MSD radix sort / binary quicksort: partitions on one bit at a time (a
/// Hoare-style scan routing "bit clear" left and "bit set" right), recursing into both halves with
/// the next-lower bit until either the range is trivial or every bit has been consumed.
///
/// This is the first "template" ported in this codebase — every prior algorithm is a
/// self-contained `SortAlgorithm` struct, but ArrayV's own class hierarchy has several concrete
/// sorts sharing one base class's logic verbatim (see Documentation/docs/reference/port-status.md's
/// cluster notes). Since this codebase has no inheritance, a
/// template becomes a stateless namespace of `static func`s taking `inout RecordingEngine`
/// explicitly, rather than the nested-closure-capturing-`engine` style every single-file algorithm
/// uses — nested closures can't be shared across two different files' `record(into:)`.
enum BinaryQuickSortingTemplate {
  private static func isBitSet(_ value: Int, _ bitIndex: Int) -> Bool {
    (value >> bitIndex) & 1 == 1
  }

  /// Hoare-style single-bit partition: routes every element with `bitIndex` clear to the left of
  /// the returned split point, and every element with `bitIndex` set to the right.
  static func partition(_ engine: inout RecordingEngine, _ p: Int, _ r: Int, _ bitIndex: Int)
    -> Int {
    var i = p - 1
    var j = r + 1
    while true {
      repeat { i += 1 } while i <= r && !isBitSet(engine.values[i], bitIndex)
      repeat { j -= 1 } while j >= p && isBitSet(engine.values[j], bitIndex)
      if i < j {
        engine.swap(i, j)
      } else {
        return j
      }
    }
  }

  static func binaryQuickSortRecursive(
    _ engine: inout RecordingEngine, _ p: Int, _ r: Int, _ bitIndex: Int
  ) {
    guard p < r, bitIndex >= 0 else { return }
    let q = partition(&engine, p, r, bitIndex)
    binaryQuickSortRecursive(&engine, p, q, bitIndex - 1)
    binaryQuickSortRecursive(&engine, q + 1, r, bitIndex - 1)
  }

  /// Same algorithm as `binaryQuickSortRecursive`, but iterative via an explicit FIFO work queue
  /// instead of the call stack (matching ArrayV's own `Queue<Task>`-based variant) — a growable
  /// array with a `head` index gives the same amortized FIFO behavior as ArrayV's `LinkedList`
  /// without needing a dedicated deque type.
  static func binaryQuickSort(_ engine: inout RecordingEngine, _ p: Int, _ r: Int, _ bitIndex: Int) {
    var tasks: [(p: Int, r: Int, bitIndex: Int)] = [(p, r, bitIndex)]
    var head = 0
    while head < tasks.count {
      let task = tasks[head]
      head += 1
      guard task.p < task.r, task.bitIndex >= 0 else { continue }
      let q = partition(&engine, task.p, task.r, task.bitIndex)
      tasks.append((task.p, q, task.bitIndex - 1))
      tasks.append((q + 1, task.r, task.bitIndex - 1))
    }
  }

  /// ArrayV's `Reads.analyzeBit`: the position of the highest set bit in the array's maximum
  /// value — the starting `bitIndex` for either driver above. `-1` (rather than trapping) when
  /// every value is `0`, matching `bitIndex >= 0`'s guard turning into an immediate no-op.
  static func mostSignificantBit(_ values: [Int]) -> Int {
    let maxValue = values.max() ?? 0
    guard maxValue > 0 else { return -1 }
    return Int.bitWidth - 1 - maxValue.leadingZeroBitCount
  }
}
