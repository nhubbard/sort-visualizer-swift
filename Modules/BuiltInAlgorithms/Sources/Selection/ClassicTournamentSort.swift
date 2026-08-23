import AlgorithmKit
import SortEngineKit

/// A tournament-tree sort: leaves hold every array index, and each internal node caches the
/// index of whichever child holds the smaller array value — repeatedly reading the root and
/// then replaying just the `O(log n)` path from the previous winner's leaf back to the root
/// (`findNext`) produces the whole sorted order without re-comparing anything outside that path.
///
/// ArrayV's own `findNext` computes this replay with branchless bit-hack arithmetic (`>> 31`,
/// `&`, `~`) purely as a JIT micro-optimization with no algorithmic meaning of its own — ported
/// here as the equivalent plain `if`/`else` over "is this side still a real subtree winner, or
/// did we just invalidate it," which is genuinely what the bit tricks compute. Also dropped:
/// ArrayV's `Highlights.markArray` calls during tree construction and each output write are
/// purely cosmetic (no counted operation, no `Reads`/`Writes` call backing them), and this
/// codebase's other ports never reproduce that category of highlight, relying solely on
/// `compare`/`swap`'s automatic primary/secondary marking instead.
///
/// Stability: `false` — a value can be compared against different opponents depending on which
/// side of the tree it lands on, so two equal elements aren't guaranteed to keep their original
/// relative order.
public struct ClassicTournamentSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "classictournamentsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Classic Tournament Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2255, coefficients: [193624, 99.5009, 0.00318444],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [8.86973, 1.0293], rSquared: 0.999267),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "trophy.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func ceilPow2(_ value: Int) -> Int {
      var r = 1
      while r < value { r *= 2 }
      return r
    }

    let size = ceilPow2(n) - 1
    let mod = n % 2
    let treeSize = n + size + mod

    let treeHandle = engine.createAuxArray(length: treeSize)
    // The real backing store for the tournament tree — `writeAux` only feeds the tape/visualizer.
    // Every slot holds either `-1` (no live candidate) or the array index of a subtree's current
    // winner.
    var tree = [Int](repeating: -1, count: treeSize)
    func setTree(_ index: Int, _ value: Int) {
      tree[index] = value
      engine.writeAux(treeHandle, at: index, value: value)
    }

    // `array[tree[a]] <= array[tree[b]]` — the smaller value wins, matching ascending output.
    func treeCompare(_ a: Int, _ b: Int) -> Bool {
      engine.compare(tree[a], tree[b], by: <=)
    }

    for i in 0..<treeSize {
      setTree(i, -1)
    }
    for i in size..<(treeSize - mod) {
      setTree(i, i - size)
    }
    var j = size
    var k = treeSize - mod
    while j > 0 {
      var i = j
      while i + 1 < k {
        setTree(i / 2, treeCompare(i, i + 1) ? tree[i] : tree[i + 1])
        i += 2
      }
      if i < k {
        setTree(i / 2, tree[i])
      }
      j /= 2
      k /= 2
    }

    // Replays the path from the previous winner's leaf up to the root, invalidating it first so
    // that "is this side still real" can be answered with a plain `!= -1` check rather than
    // needing to track which values the caller already consumed.
    func findNext() -> Int {
      var path = tree[0] + size
      while path > 0 {
        setTree(path, -1)
        path = (path - 1) / 2
      }

      var node = tree[0] + size
      while node > 0 {
        let sibling = node % 2 == 1 ? node + 1 : node - 1
        let nodeValid = tree[node] != -1
        let siblingValid = tree[sibling] != -1
        let winner: Int
        if nodeValid && siblingValid {
          winner =
            node < sibling
            ? (treeCompare(node, sibling) ? tree[node] : tree[sibling])
            : (treeCompare(sibling, node) ? tree[sibling] : tree[node])
        } else if nodeValid {
          winner = tree[node]
        } else if siblingValid {
          winner = tree[sibling]
        } else {
          winner = -1
        }
        node = (node - 1) / 2
        if winner != -1 {
          setTree(node, winner)
        }
      }
      return engine.values[tree[0]]
    }

    let outHandle = engine.createAuxArray(length: n)
    var output = [Int](repeating: 0, count: n)
    output[0] = engine.values[tree[0]]
    engine.writeAux(outHandle, at: 0, value: output[0])
    for i in 1..<n {
      output[i] = findNext()
      engine.writeAux(outHandle, at: i, value: output[i])
    }

    for i in 0..<n {
      engine.setValue(i, output[i])
    }
    engine.deleteAuxArray(treeHandle)
    engine.deleteAuxArray(outHandle)
  }
}
