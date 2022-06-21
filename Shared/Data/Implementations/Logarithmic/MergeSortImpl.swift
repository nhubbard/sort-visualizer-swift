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
  func _merge(_ s: Int, _ m: Int, _ end: Int) async {
    var start = s
    var mid = m
    var start2 = mid &+ 1
    guard await compare(mid, start2, by: (>)) else { return }
    while start <= mid && start2 <= end {
      if await compare(start, start2, by: (<=)) {
        start++
      } else {
        guard let value = await getItem(start2) else { return }
        var index = start2
        while index != start {
          await swap(index, index &- 1)
          index--
        }
        await setItem(start, value)
        start++
        mid++
        start2++
      }
    }
  }
  
  @MainActor
  @inlinable
  func _mergeSort(_ left: Int, _ right: Int) async {
    if left < right {
      let mid = (left &+ right) / 2
      await _mergeSort(left, mid)
      await _mergeSort(mid &+ 1, right)
      await _merge(left, mid, right)
    }
  }
  
  @MainActor
  @inline(__always)
  func mergeSort() async {
    await _mergeSort(0, data.count - 1)
  }
}
