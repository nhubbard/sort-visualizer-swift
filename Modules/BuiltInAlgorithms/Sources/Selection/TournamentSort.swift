import AlgorithmKit
import SortEngineKit

/// A recursive knockout-bracket tournament sort. `matches` packs each bracket node as three
/// slots — `(winner, winners, losers)` — where `winner` is the player index currently on top,
/// and `winners`/`losers` are *references* that are either a player leaf (encoded as `-index`,
/// so `<= 0`) or another match node's root offset (`> 0`). `getPlayer` resolves either kind of
/// reference down to a concrete player index in one step.
///
/// After each extraction, `rebuild` replays only the path from the just-emptied leaf back to the
/// tournament's root: it recurses into the `winners` side first (the side that just lost its
/// champion) to find that subtree's new champion, then runs a single match between that new
/// champion and the current `losers` side, swapping which reference is "winners" vs. "losers" if
/// the loser side's own champion turns out to still be smaller.
///
/// One deliberate departure from ArrayV's `TournamentSort.java`: its `tourneyCompare(a, b)` is
/// called with already-dereferenced *values*, not indices, yet still calls
/// `Highlights.markArray(2, a)`/`markArray(3, b)` — a real ArrayV bug that highlights whatever
/// index equals the compared *value*, not the cell actually being compared. This port compares
/// the real player indices directly via `engine.compare`, which marks the cells that are
/// genuinely being read.
///
/// Stability: `false` — which of two equal players reaches a given match depends on the bracket
/// shape, not their original order.
public struct TournamentSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "tournamentsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tournament Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2151, coefficients: [195846, 105.921, 0.00366244],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "medal.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let matchesHandle = engine.createAuxArray(length: 6 * n)
    // The real backing store for the bracket — `writeAux` only feeds the tape/visualizer.
    var matches = [Int](repeating: 0, count: 6 * n)
    func setSlot(_ index: Int, _ value: Int) {
      matches[index] = value
      engine.writeAux(matchesHandle, at: index, value: value)
    }

    func isPlayer(_ ref: Int) -> Bool { ref <= 0 }
    func makePlayer(_ index: Int) -> Int { -index }
    func getWinner(_ root: Int) -> Int { matches[root] }
    func getWinners(_ root: Int) -> Int { matches[root + 1] }
    func getLosers(_ root: Int) -> Int { matches[root + 2] }
    func setWinner(_ root: Int, _ winner: Int) { setSlot(root, winner) }
    func setWinners(_ root: Int, _ winners: Int) { setSlot(root + 1, winners) }
    func setLosers(_ root: Int, _ losers: Int) { setSlot(root + 2, losers) }
    func setMatch(_ root: Int, _ winner: Int, _ winners: Int, _ losers: Int) {
      setWinner(root, winner)
      setWinners(root, winners)
      setLosers(root, losers)
    }
    func getPlayer(_ ref: Int) -> Int { isPlayer(ref) ? abs(ref) : getWinner(ref) }

    func makeMatch(_ top: Int, _ bot: Int, _ root: Int) -> Int {
      let topWinner = getPlayer(top)
      let botWinner = getPlayer(bot)
      if engine.compare(topWinner, botWinner, by: <=) {
        setMatch(root, topWinner, top, bot)
      } else {
        setMatch(root, botWinner, bot, top)
      }
      return root
    }

    func knockout(_ i: Int, _ k: Int, _ root: Int) -> Int {
      if i == k { return makePlayer(i) }
      let mid = (i + k) / 2
      let leftRef = knockout(i, mid, 2 * root)
      let rightRef = knockout(mid + 1, k, 2 * root + 3)
      return makeMatch(leftRef, rightRef, root)
    }

    func rebuild(_ root: Int) -> Int {
      if isPlayer(getWinners(root)) {
        return getLosers(root)
      }
      setWinners(root, rebuild(getWinners(root)))
      if engine.compare(getPlayer(getLosers(root)), getPlayer(getWinners(root)), by: <) {
        setWinner(root, getPlayer(getLosers(root)))
        let previousLosers = getLosers(root)
        setLosers(root, getWinners(root))
        setWinners(root, previousLosers)
      } else {
        setWinner(root, getPlayer(getWinners(root)))
      }
      return root
    }

    var tourney = knockout(0, n - 1, 3)

    func pop() -> Int {
      let result = engine.values[getPlayer(tourney)]
      tourney = isPlayer(tourney) ? 0 : rebuild(tourney)
      return result
    }

    let outHandle = engine.createAuxArray(length: n)
    var output = [Int](repeating: 0, count: n)
    for i in 0..<n {
      output[i] = pop()
      engine.writeAux(outHandle, at: i, value: output[i])
    }

    for i in 0..<n {
      engine.setValue(i, output[i])
    }
    engine.deleteAuxArray(matchesHandle)
    engine.deleteAuxArray(outHandle)
  }
}
