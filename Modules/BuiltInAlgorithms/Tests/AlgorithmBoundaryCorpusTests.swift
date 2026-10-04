import AlgorithmKit
@testable import BuiltInAlgorithms
import SortEngineKit
import Testing

/// A deterministic correctness matrix over each algorithm's selectable size range. The seed
/// depends only on the algorithm ID and size, so failures can be reproduced without XCTest's
/// process-global random state.
struct AlgorithmBoundaryCorpusTests {
  private static let internalBoundaries = [15, 16, 17, 31, 32, 33, 63, 64, 65]

  @Test
  func practicalAlgorithmsSortAtSelectableBoundaries() {
    let algorithms = AllBuiltInAlgorithms.sorts.filter {
      $0.metadata.category != .impractical && !($0 is IndexSort)
    }
    #expect(algorithms.count + AllBuiltInAlgorithms.sorts.filter { $0.metadata.category == .impractical }.count + 1 == 196)
    for algorithm in algorithms {
      let range = algorithm.metadata.effectiveSizeRange(operationCap: RecordingEngine.defaultOperationCap)
      let candidates = [range.lowerBound, range.lowerBound + 1, range.lowerBound + 2]
        + Self.internalBoundaries + [range.upperBound - 1, range.upperBound]
      let sizes = Set(candidates.filter { range.contains($0) }).sorted()
      for size in sizes {
        let seed = Self.seed(for: algorithm.id.rawValue, size: size)
        let permutation = Self.permutation(size: size, seed: seed)
        let duplicates = Self.duplicates(size: size, seed: seed)
        var inputs: [(String, [Int])] = [("permutation", permutation), ("duplicates", duplicates)]
        if size == range.lowerBound || size == range.upperBound {
          inputs += [
            ("ascending", Array(1 ... size)),
            ("descending", Array((1 ... size).reversed())),
            ("equal", [Int](repeating: 1, count: size)),
          ]
        }
        for (shape, input) in inputs {
          Self.expectSorted(algorithm, input: input, seed: seed, shape: shape)
        }
      }
    }
  }

  @Test
  func impracticalAlgorithmsSortAtTheirMinimumSelectableSize() {
    let algorithms = AllBuiltInAlgorithms.sorts.filter { $0.metadata.category == .impractical }
    #expect(!algorithms.isEmpty)
    for algorithm in algorithms {
      let size = algorithm.metadata.sizeRange.lowerBound
      let seed = Self.seed(for: algorithm.id.rawValue, size: size)
      let inputs: [(String, [Int])] = [
        ("permutation", Self.permutation(size: size, seed: seed)),
        ("duplicates", Self.duplicates(size: size, seed: seed)),
        ("ascending", Array(1 ... size)),
        ("descending", Array((1 ... size).reversed())),
      ]
      for (shape, input) in inputs {
        Self.expectSorted(algorithm, input: input, seed: seed, shape: shape)
      }
    }
  }

  @Test
  func indexSortSortsOnlyItsDocumentedPermutationDomainAtBoundaries() {
    let algorithm = IndexSort()
    let range = algorithm.metadata.effectiveSizeRange(operationCap: RecordingEngine.defaultOperationCap)
    let sizes = Set(([range.lowerBound, range.lowerBound + 1, range.upperBound - 1, range.upperBound]
        + Self.internalBoundaries).filter { range.contains($0) }).sorted()
    for size in sizes {
      let seed = Self.seed(for: algorithm.id.rawValue, size: size)
      for base in [-7, 1] {
        let permutation = Self.permutation(size: size, seed: seed).map { $0 + base - 1 }
        Self.expectSorted(algorithm, input: permutation, seed: seed, shape: "permutation base \(base)")
      }
    }
  }

  private static func expectSorted(
    _ algorithm: any SortAlgorithm, input: [Int], seed: UInt64, shape: String
  ) {
    var engine = RecordingEngine(values: input, randomSeed: seed)
    algorithm.record(into: &engine)
    let expected = input.sorted()
    #expect(engine.values == expected,
            "\(algorithm.id.rawValue), size \(input.count), \(shape), seed \(seed): \(input) -> \(engine.values)")
  }

  private static func seed(for id: String, size: Int) -> UInt64 {
    id.utf8.reduce(UInt64(size) &+ 0xA076_1D64_78BD_642F) {
      ($0 ^ UInt64($1)) &* 0xE703_7ED1_A0B4_28DB
    }
  }

  private static func permutation(size: Int, seed: UInt64) -> [Int] {
    var values = Array(1 ... size)
    var state = seed
    if size > 1 {
      for index in stride(from: size - 1, through: 1, by: -1) {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        values.swapAt(index, Int((state >> 32) % UInt64(index + 1)))
      }
    }
    return values
  }

  private static func duplicates(size: Int, seed: UInt64) -> [Int] {
    var state = seed
    return (0 ..< size).map { _ in
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Int((state >> 32) % 4) + 1
    }
  }
}
