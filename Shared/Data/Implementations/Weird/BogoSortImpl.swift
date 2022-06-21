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
    guard await enforceRunning() else {
      return .stopped
    }
    let values = await data.concurrentMap { $0.value }
    let permutations = values.uniquePermutations()
    for p in permutations {
      guard await enforceRunning() else { return .stopped }
      await data.indices.concurrentForEach { [self] i in
        guard
          await enforceRunning(),
          let pV = p[i],
          await getValue(i) != pV else { return }
        await changeColor(index: i, color: .orange)
        await setValue(i, pV)
        await operate()
        await delay()
        await resetColor(index: i)
      }
      if data == data.sorted() {
        break
      }
    }
    return data == data.sorted() ? .finished : .stopped
  }
}
