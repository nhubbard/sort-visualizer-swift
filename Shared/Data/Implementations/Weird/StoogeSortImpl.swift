//
//  StoogeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import CollectionConcurrencyKit

extension SortViewModel {
  @MainActor
  func _stoogeSort(_ start: Int, _ end: Int) async {
    guard await enforceRunning() else {
      return
    }
    // Only present to ensure that users don't think the program has frozen
    Task.detached {
      await (start..<end).concurrentForEach { [self] i in
        await changeColor(index: i, color: .orange)
        await delay()
      }
    }
    let len = end - start + 1
    if len <= 1 {
      return
    } else if len == 2 {
      guard let startValue = await getValue(index: start),
            let endValue = await getValue(index: end) else {
        return
      }
      if startValue > endValue {
        await swap(start, end)
      }
      return
    }
    Task.detached {
      await (start..<end).concurrentForEach { [self] i in
        await delay()
        await resetColor(index: i)
      }
    }
    let len23 = Int(ceil(Double(len) * 2 / 3))
    await _stoogeSort(start, start + len23 - 1)
    await _stoogeSort(end - len23 + 1, end)
    await _stoogeSort(start, start + len23 - 1)
  }
  
  @MainActor
  func stoogeSort() async {
    await _stoogeSort(0, data.count - 1)
  }
}
