//
//  BubbleSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  // Based on inspiration (github:Myphz/sortvisualizer)
  @MainActor
  @inlinable
  func bubbleSort() async {
    guard await enforceRunning() else {
      return
    }
    for i in 1..<data.count {
      guard await enforceRunning() else {
        return
      }
      for j in 0..<(data.count - i) {
        guard await enforceRunning() else {
          return
        }
        if await compare(firstIndex: j, secondIndex: j + 1) {
          await swap(j, j + 1)
        }
      }
    }
  }
}
