import Testing

@testable import DesignSystemKit

@Suite
struct HeaderQuickSortTests {
  @Test
  func everyPermutationOfSixLettersSortsThroughRecordedSwaps() {
    func verify(_ remaining: [Int], _ prefix: [Int]) {
      if remaining.isEmpty {
        var replayed = prefix
        for step in HeaderQuickSort.steps(for: prefix) {
          if case .swap(let first, let second) = step {
            replayed.swapAt(first, second)
          }
        }
        #expect(replayed == Array(0..<6))
        return
      }
      for (position, value) in remaining.enumerated() {
        var next = remaining
        next.remove(at: position)
        verify(next, prefix + [value])
      }
    }

    verify(Array(0..<6), [])
  }

  @Test
  func repeatedGlyphsKeepDistinctDestinations() {
    let title = Array("SORT SYMPHONY")
    let shuffled = Array(title.indices).indices.reversed()
    var replayed = Array(shuffled)
    for step in HeaderQuickSort.steps(for: replayed) {
      if case .swap(let first, let second) = step {
        replayed.swapAt(first, second)
      }
    }
    #expect(replayed.map { title[$0] } == title)
  }
}
