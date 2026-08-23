import AlgorithmKit
import SortEngineKit

/// A sort built directly on the Tower of Hanoi puzzle's own move sequence. Two auxiliary stacks
/// (`stack2`, `stack3`) stand in for the puzzle's other two pegs; the main array is the third
/// "peg," consumed from the front (`sp` walks forward past cells already moved onto a stack) and
/// rebuilt from the back (`moveToMain` writes into `array[sp]` after decrementing `sp`).
///
/// The core move is `hanoi(startStack, goRight, endCon)`: it replays the *iterative* Tower of Hanoi
/// algorithm (moving a "tower" of already-sorted elements between pegs one at a time, alternating
/// which peg the smallest disk visits) until one of three end conditions fires. Because the
/// recursion depth of a real Tower of Hanoi move isn't known in advance here, this is iterative —
/// `validNumberMoves` recognizes the `2^k - 1` move counts a real Hanoi tower move always produces,
/// and `getHeight` recovers `k` from the move count actually taken. Each move of "one disk" here is
/// actually a move of *one run of equal elements* (`moveFromMain`/`moveToMain`/`moveBetweenStacks`
/// each carry every immediately-following duplicate along with the element that triggered the
/// move), which is what keeps the puzzle's peg-ordering invariant valid in the presence of ties.
///
/// `removeFromMainStack` uses one `hanoi` call to find how far up `stack2` (which is always kept
/// sorted) the next unsorted element belongs, then a second and third to shuffle the elements above
/// that point out of the way, insert the new element, and shuffle them back — an insertion sort,
/// just performed by relocating whole towers instead of shifting array cells. `returnToMainStack`
/// unwinds all of `stack2` back onto the array once every element has been inserted.
///
/// ArrayV files this next to its other insertion sorts on disk but categorizes it at runtime as an
/// "Impractical Sort" and flags it unreasonable past array size 32 — the move count per insertion
/// might look `O(log n)`-ish from the puzzle's own recursion depth, but growth-model calibration
/// measured genuinely exponential real operation counts (an `exponential` curve fit the measured
/// data far better than any polynomial family, R² > 0.998, consistent across every shuffle type
/// tried), not just a large constant factor — `sizeRange`'s upper bound of 16 and the
/// `exponential` complexity below come directly from that measurement, not the puzzle's own
/// aspirational move count.
public struct HanoiSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "hanoisort")
  public let metadata = AlgorithmMetadata(
    displayName: "Hanoi Sort",
    category: .impractical,
    sizeRange: 4...16,
    growthModel: OperationGrowthModel(
      anchorSize: 16, coefficients: [156426, 107109, 36670.3, 8369.74, 1432.75, 196.209],
      measuredSafeCeiling: 16),
    detectedGrowthModel: DetectedGrowthModel(
      family: .exponential, coefficients: [2.73103, 1.98323], rSquared: 0.998731),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(2^n)", worst: "O(2^n)"),
    spaceComplexity: "O(n)",
    iconName: "square.3.stack.3d"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    enum StackID { case two, three }

    var stack2: [Int] = []
    var stack3: [Int] = []
    let stack2Handle = engine.createAuxArray(length: n)
    let stack3Handle = engine.createAuxArray(length: n)

    func push(_ id: StackID, _ value: Int) {
      switch id {
      case .two:
        engine.writeAux(stack2Handle, at: stack2.count, value: value)
        stack2.append(value)
      case .three:
        engine.writeAux(stack3Handle, at: stack3.count, value: value)
        stack3.append(value)
      }
    }
    func pop(_ id: StackID) -> Int {
      switch id {
      case .two: return stack2.removeLast()
      case .three: return stack3.removeLast()
      }
    }
    func peek(_ id: StackID) -> Int? {
      switch id {
      case .two: return stack2.last
      case .three: return stack3.last
      }
    }
    func isEmpty(_ id: StackID) -> Bool {
      switch id {
      case .two: return stack2.isEmpty
      case .three: return stack3.isEmpty
      }
    }

    var sp = 0
    var unsorted = 0
    var target = 0
    var targetMoves = 0

    @discardableResult
    func moveFromMain(_ id: StackID, checkUnsorted: Bool) -> Int {
      var duplicates = 1
      push(id, engine.values[sp])
      sp += 1
      var endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
      while !endOnLength, engine.values[sp] == peek(id) {
        duplicates += 1
        push(id, engine.values[sp])
        sp += 1
        endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
      }
      return duplicates
    }

    func moveToMain(_ id: StackID) {
      sp -= 1
      engine.setValue(sp, pop(id))
      while !isEmpty(id), peek(id) == engine.values[sp] {
        sp -= 1
        engine.setValue(sp, pop(id))
      }
    }

    func moveBetweenStacks(_ from: StackID, _ to: StackID) {
      push(to, pop(from))
      while !isEmpty(from), peek(from) == peek(to) {
        push(to, pop(from))
      }
    }

    func validNumberMoves(_ moves: Int) -> Bool {
      if moves == 0 { return true }
      if moves % 2 == 0 { return false }
      return validNumberMoves(moves / 2)
    }

    func getHeight(_ movesPlus1: Int) -> Int {
      if movesPlus1 == 1 { return 0 }
      return getHeight(movesPlus1 / 2) + 1
    }

    func endConMet(_ endCon: Int, _ moves: Int) -> Bool {
      guard validNumberMoves(moves) else { return false }
      switch endCon {
      case 1: return stack2.isEmpty || target <= stack2.last!
      case 2: return moves == targetMoves
      case 3: return stack2.isEmpty
      default: preconditionFailure("unknown end condition")
      }
    }

    @discardableResult
    func hanoi(_ startStack: Int, _ goRight: Bool, _ endCon: Int) -> Int {
      var moves = 0
      var minPoleLoc = startStack

      if !endConMet(endCon, moves) {
        moves += 1
        switch minPoleLoc {
        case 1:
          if goRight {
            moveFromMain(.two, checkUnsorted: true)
            minPoleLoc = 2
          } else {
            moveFromMain(.three, checkUnsorted: true)
            minPoleLoc = 3
          }
        case 2:
          if goRight {
            moveBetweenStacks(.two, .three)
            minPoleLoc = 3
          } else {
            moveToMain(.two)
            minPoleLoc = 1
          }
        default: // 3
          if goRight {
            moveToMain(.three)
            minPoleLoc = 1
          } else {
            moveBetweenStacks(.three, .two)
            minPoleLoc = 2
          }
        }
      }

      while !endConMet(endCon, moves) {
        moves += 2
        switch minPoleLoc {
        case 1:
          if !stack2.isEmpty, stack3.isEmpty || stack2.last! < stack3.last! {
            moveBetweenStacks(.two, .three)
          } else {
            moveBetweenStacks(.three, .two)
          }
          if goRight {
            moveFromMain(.two, checkUnsorted: true)
            minPoleLoc = 2
          } else {
            moveFromMain(.three, checkUnsorted: true)
            minPoleLoc = 3
          }
        case 2:
          if stack3.isEmpty || (sp < unsorted && engine.values[sp] < stack3.last!) {
            moveFromMain(.three, checkUnsorted: true)
          } else {
            moveToMain(.three)
          }
          if goRight {
            moveBetweenStacks(.two, .three)
            minPoleLoc = 3
          } else {
            moveToMain(.two)
            minPoleLoc = 1
          }
        default: // 3
          if stack2.isEmpty || (sp < unsorted && engine.values[sp] < stack2.last!) {
            moveFromMain(.two, checkUnsorted: true)
          } else {
            moveToMain(.two)
          }
          if goRight {
            moveToMain(.three)
            minPoleLoc = 1
          } else {
            moveBetweenStacks(.three, .two)
            minPoleLoc = 2
          }
        }
      }

      return moves
    }

    func removeFromMainStack() {
      target = engine.values[sp]
      let moves = hanoi(2, true, 1)
      let height = getHeight(moves + 1)
      targetMoves = moves
      let evenHeight = height % 2 == 0

      if evenHeight {
        hanoi(1, true, 2)
      }
      unsorted += moveFromMain(.two, checkUnsorted: false)
      hanoi(3, evenHeight, 2)
    }

    func returnToMainStack() {
      let moves = hanoi(2, true, 3)
      let height = getHeight(moves + 1)
      if height % 2 == 1 {
        targetMoves = moves
        hanoi(3, true, 2)
      }
    }

    while unsorted < n {
      removeFromMainStack()
    }
    returnToMainStack()

    engine.deleteAuxArray(stack2Handle)
    engine.deleteAuxArray(stack3Handle)
  }
}
