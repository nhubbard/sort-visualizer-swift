//
//  QuickSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import CollectionConcurrencyKit

extension SortViewModel {
  // Based on the original inspiration for this app (github:Myphz/sortvisualizer)
  @MainActor
  func _quickSort(_ left: Int, _ right: Int) async {
    guard await enforceRunning() else {
      return
    }
    if left < right {
      let pivot = left
      await changeColor(index: pivot, color: .red)
      var i = left
      var j = right
      await changeColor(index: j, color: .blue)
      while i < j {
        guard await enforceRunning() else {
          return
        }
        while await compare(firstIndex: pivot, secondIndex: i) && i < j {
          guard await enforceRunning() else {
            return
          }
          await resetColor(index: i)
          i++
          await changeColor(index: i, color: .green)
        }
        while await !compare(firstIndex: pivot, secondIndex: j) {
          guard await enforceRunning() else {
            return
          }
          await resetColor(index: j)
          j--
          await changeColor(index: j, color: .blue)
        }
        await changeColor(index: pivot, color: .red)
        if i < j {
          await swap(i, j)
        }
      }
      await swap(pivot, j)
      await [i, j, pivot].concurrentForEach { [self] index in
        guard await enforceRunning() else {
          return
        }
        await resetColor(index: index)
      }
      await _quickSort(left, j - 1)
      await _quickSort(j + 1, right)
    }
  }
  
  @MainActor
  func quickSort() async {
    guard await enforceRunning() else {
      return
    }
    await _quickSort(0, data.count - 1)
  }
}
