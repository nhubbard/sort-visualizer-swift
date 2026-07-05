//
//  SelectionSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  // This is another algorithm that I didn't rewrite following the JS implementation; it ended up taking 400x
  // longer and required a ton of iterations and concurrency helpers.
  @MainActor
  @inlinable
  func selectionSort() async {
    guard await enforceRunning() else { return }
    for i in 0..<(data.count &- 1) {
      guard await enforceRunning() else { return }
      var key = i
      for j in (i &+ 1)..<(data.count) where await compare(key, j, clear: true) {
        guard await enforceRunning() else { return }
        key = j
      }
      guard i != key else { continue }
      await swap(i, key)
    }
  }
}
