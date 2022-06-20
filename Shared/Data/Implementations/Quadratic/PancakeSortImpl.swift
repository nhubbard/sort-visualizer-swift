//
//  PancakeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func _flip(_ k: Int) async {
    guard await enforceRunning() else {
      return
    }
    var k = k
    var left = 0
    while left < k {
      guard await enforceRunning() else {
        return
      }
      await swap(left, k)
      k--
      left++
    }
  }
  
  @MainActor
  @inlinable
  func _maxIndex(_ k: Int) async -> Int {
    guard await enforceRunning() else {
      return -1
    }
    var index = 0
    for i in 0..<k {
      guard await enforceRunning() else {
        return -1
      }
      if await compare(firstIndex: i, secondIndex: index) {
        index = i
      }
    }
    return index
  }
  
  @MainActor
  @inlinable
  func pancakeSort() async {
    guard await enforceRunning() else {
      return
    }
    var n = data.count
    while n > 1 {
      guard await enforceRunning() else {
        return
      }
      let maxIndex = await _maxIndex(n)
      if maxIndex != n {
        await _flip(maxIndex)
        await _flip(n &- 1)
      }
      n--
    }
  }
}
