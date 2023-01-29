//
//  DeterministicBogoSortImpl.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/17/22.
//

import Algorithms
import Foundation
import CollectionConcurrencyKit

extension SortViewModel {
  @MainActor
  @inlinable
  func bogoSort() async -> SortStatus {
    guard await enforceRunning() else { return .stopped }
    let values = await data.concurrentMap(withPriority: .high) { $0.value }
    // Don't use uniquePermutations(); we're guaranteed to not have any duplicate values in the array, and the unique check slows down the operation from O(1) to O(n)
    let permutations = values.permutations(ofCount: data.count)
    for p in permutations {
      guard await enforceRunning() else { return .stopped }
      await data.indices.concurrentForEach(withPriority: .high) { [self] i in
        // It may look weird that I'm wrapping a "non-null" value in an Optional result, but it stops the compiler from complaining about it, so I call that a win.
        // The result is actually nullable, since we're attempting to get an index from an array that might be out of bounds.
        guard
          await enforceRunning(),
          let pV = Optional(p[i]),
          await getValue(i) != pV else { return }
        await changeColor(index: i, color: .orange)
        await setValue(i, pV)
        await operate()
        await resetColor(index: i)
      }
      if data == data.sorted() { break }
    }
    return data == data.sorted() ? .finished : .stopped
  }
}
