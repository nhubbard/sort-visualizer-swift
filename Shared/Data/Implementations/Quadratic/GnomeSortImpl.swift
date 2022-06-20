//
//  GnomeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func gnomeSort() async {
    guard await enforceRunning() else {
      return
    }
    var i = 1
    var j = 2
    while i < data.count {
      guard await enforceRunning() else {
        return
      }
      if await !compare(firstIndex: i &- 1, secondIndex: i) {
        i = j
        j++
      } else {
        await swap(i &- 1, i)
        i--
        if i == 0 {
          i = j
          j++
        }
      }
    }
  }
}
