//
//  StoogeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func _stoogeSort(_ start: Int, _ end: Int) async {
    guard await enforceRunning() else { return }
    // Only present to ensure that users don't think the program has frozen
    let len = end &- start &+ 1
    if len <= 1 {
      return
    } else if len == 2 {
      guard await getValue(start) != nil, await getValue(end) != nil else { return }
      if await compare(start, end, by: (>)) {
        await swap(start, end)
      }
      return
    }
    let len23 = Int(ceil(Double(len) * 2 / 3))
    await _stoogeSort(start, start &+ len23 - 1)
    await _stoogeSort(end - len23 &+ 1, end)
    await _stoogeSort(start, start &+ len23 - 1)
  }
  
  @MainActor
  @inlinable
  func stoogeSort() async {
    await _stoogeSort(0, data.count - 1)
  }
}
