//
//  MergeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  @inlinable
  func _merge(_ low: Int, _ mid: Int, _ high: Int) async {
    var i = low
    var j = mid &+ 1
    var k = 0
    var temp = [Int](repeating: 0, count: high &- low &+ 1)
    while i <= mid && j <= high {
      guard await enforceRunning() else { return }
      if await compare(i, j, by: (<)) {
        temp[k++] = data[i++].value
      } else {
        temp[k++] = data[j++].value
      }
    }
    while j <= high {
      temp[k++] = data[j++].value
    }
    while i <= mid {
      temp[k++] = data[i++].value
    }
    i = low
    k = 0
    while i <= high {
      await setValue(i, temp[k])
      await resetColor(index: i)
      i++
      k++
    }
  }

  @MainActor
  @inlinable
  func _mergeSort(_ left: Int, _ right: Int) async {
    if left < right {
      let mid = (left &+ right) / 2
      await _mergeSort(left, mid)
      await _mergeSort(mid &+ 1, right)
      if await compare(mid, mid &+ 1, by: (>)) {
        await _merge(left, mid, right)
      }
    }
  }

  @MainActor
  @inlinable
  func mergeSort() async {
    await _mergeSort(0, data.count &- 1)
  }
}
