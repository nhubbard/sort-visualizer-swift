import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SIERPINSKI`. Recursively builds an index-permutation array by
/// splitting each range into thirds and biasing the last two thirds' indices upward by increasing
/// amounts before recursing into all three thirds — the same recursive thirds-based subdivision
/// that produces a Sierpinski triangle — then gathers the array's values through that permutation.
public struct SierpinskiShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "sierpinski")
  public let metadata = ShuffleMetadata(displayName: "Sierpinski Triangle")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    var triangle = [Int](repeating: 0, count: n)
    triangleRec(&triangle, a: 0, b: n)

    let original = engine.values
    for i in 0..<n {
      engine.setValue(i, original[triangle[i]])
    }
  }

  private func triangleRec(_ triangle: inout [Int], a: Int, b: Int) {
    guard b - a >= 2 else { return }
    if b - a == 2 {
      triangle[a + 1] += 1
      return
    }

    let h = (b - a) / 3
    let t1 = (a + a + b) / 3
    let t2 = (a + b + b + 2) / 3

    for i in a..<t1 { triangle[i] += h }
    for i in t1..<t2 { triangle[i] += 2 * h }

    triangleRec(&triangle, a: a, b: t1)
    triangleRec(&triangle, a: t1, b: t2)
    triangleRec(&triangle, a: t2, b: b)
  }
}
