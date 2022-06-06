//
//  HeapSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  func _heapify(_ length: Int, _ i: Int) async {
    guard await enforceRunning() else {
      return
    }
    let indices = data.indices
    var largest = i
    let left = i * 2 + 1
    let right = left + 1
    if indices.contains(left) && indices.contains(largest) {
      let firstCompare = await compare(firstIndex: left, secondIndex: largest)
      if left < length && firstCompare {
        largest = left
      }
    }
    if indices.contains(right) && indices.contains(largest) {
      let secondCompare = await compare(firstIndex: right, secondIndex: largest)
      if right < length && secondCompare {
        largest = right
      }
    }
    if largest != i {
      await swap(i, largest)
      await _heapify(length, largest)
    }
  }
  
  @MainActor
  func heapSort() async {
    guard await enforceRunning() else {
      return
    }
    let length = data.count
    var i = length / 2 - 1
    var k = length - 1
    while i >= 0 {
      guard await enforceRunning() else {
        return
      }
      await _heapify(length, i)
      i--
    }
    while k >= 0 {
      guard await enforceRunning() else {
        return
      }
      await swap(0, k)
      await _heapify(k, 0)
      k--
    }
  }
}
