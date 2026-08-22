import AlgorithmKit
import SortEngineKit

public struct StrandSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "strandsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Strand Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 691, coefficients: [239777, 692.5, 0.5],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "list.number"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    if n < 2 { return }

    let subListHandle = engine.createAuxArray(length: n)
    // subList never needs more than n slots across the algorithm's lifetime — every index used
    // below is provably bounded by n — so a fixed-capacity array stands in for the JS's
    // auto-extending plain array, which relies on overwriting arbitrary earlier indices
    // (writeSubList(0, ...) at the top of every pass) rather than ever growing past n.
    var subList = [Int](repeating: 0, count: n)

    func writeSubList(_ index: Int, _ value: Int) {
      subList[index] = value
      engine.writeAux(subListHandle, at: index, value: value)
    }

    func mergeTo(_ a: Int, _ m: Int, _ b: Int) {
      var a = a
      var m = m
      var i = 0
      let s = m - a
      while i < s && m < b {
        if subList[i] < engine.values[m] {
          engine.setValue(a, subList[i])
          a += 1
          i += 1
        } else {
          engine.setValue(a, engine.values[m])
          a += 1
          m += 1
        }
      }
      while i < s {
        engine.setValue(a, subList[i])
        a += 1
        i += 1
      }
    }

    var j = n
    var k = j
    while j > 0 {
      writeSubList(0, engine.values[0])
      k -= 1

      var i = 0
      var p = 0
      for m in 1..<j {
        if engine.values[m] >= subList[i] {
          i += 1
          writeSubList(i, engine.values[m])
          k -= 1
        } else {
          engine.setValue(p, engine.values[m])
          p += 1
        }
      }

      mergeTo(k, j, n)
      j = k
    }

    engine.deleteAuxArray(subListHandle)
  }
}
