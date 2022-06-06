//
//  BogoSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  func _shuffleBogo() async {
    guard await enforceRunning() else {
      return
    }
    for i in 0..<data.count {
      guard await enforceRunning() else {
        return
      }
      await swap(i, Int.random(in: data.indices))
      await delay()
    }
  }
  
  @MainActor
  func bogoSort() async {
    guard await enforceRunning() else {
      return
    }
    while data != data.sorted() {
      guard await enforceRunning() else {
        return
      }
      await _shuffleBogo()
    }
  }
}
