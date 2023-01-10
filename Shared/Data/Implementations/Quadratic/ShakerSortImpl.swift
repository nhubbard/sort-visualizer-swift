//
//  ShakerSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func shakerSort() async {
    guard await enforceRunning() else { return }
    var sorted = true
    while sorted {
      guard await enforceRunning() else { return }
      for i in 0..<(data.count - 1) {
        guard await enforceRunning() else { return }
        if await compare(i, i &+ 1) {
          await swap(i, i &+ 1)
          sorted = true
        }
      }
      if !sorted { break }
      sorted = false
      let sequence = 1..<(data.count &- 1)
      for j in sequence.reversed() {
        guard await enforceRunning() else { return }
        if await compare(j &- 1, j) {
          await swap(j &- 1, j)
          sorted = true
        }
      }
    }
  }
}
