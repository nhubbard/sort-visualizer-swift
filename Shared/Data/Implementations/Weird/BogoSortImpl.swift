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
  func bogoSort() async {
    guard await enforceRunning() else {
      return
    }
    let values = await data.concurrentMap { $0.value }
    var iterator = values.uniquePermutations().makeIterator()
    var finished = false
    while !finished {
      var cache: [[Int]?] = []
      for _ in (0..<64) {
        cache.append(iterator.next())
        await cache.concurrentForEach { [self] p in
          if p != nil {
            guard await enforceRunning() && !finished else { return }
            await data.indices.concurrentForEach { [self] index in
              guard await enforceRunning(), let pV = p![index], await getValue(index: index) != pV else { return }
              await changeColor(index: index, color: .orange)
              await setValue(index: index, newValue: pV)
              await operate()
              await delay()
              await resetColor(index: index)
            }
            await delay()
            if data == data.sorted() {
              finished = true
              return
            }
          }
        }
        cache.removeAll()
      }
    }
  }
}
