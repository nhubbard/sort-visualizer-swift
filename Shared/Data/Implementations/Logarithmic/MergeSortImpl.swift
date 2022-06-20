//
//  MergeSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

enum SortStatus {
  case finished
  case stopped
}

extension SortViewModel {
  // Loosely based on original inspiration (github:Myphz/sortvisualizer)
  @MainActor
  @discardableResult
  @inlinable
  func _mergeSort(_ start: Int, _ end: Int) async -> SortStatus {
    guard await enforceRunning() else {
      return .stopped
    }
    if start >= end - 1 {
      return .finished
    }
    // ~ is bitwise NOT operator; the JS version uses a unique ~~ operator for double bitwise NOT.
    let mid = start + ~(~((end - start) / 2))
    await _mergeSort(start, mid)
    await _mergeSort(mid, end)
    var cache = Array(repeating: data[0], count: end - start)
    var k = mid
    // This was previously a C-style for loop with *two* updates, written as such:
    // for (var i = start, r = 0; i < mid; r++, i++)
    var r = 0
    for i in start..<mid {
      guard await enforceRunning() else {
        return .stopped
      }
      guard let kVal = await getValue(index: k),
            let iVal = await getValue(index: i) else {
        continue
      }
      while k < end && kVal < iVal {
        guard await enforceRunning() else {
          return .stopped
        }
        guard let kV = await getItem(index: k) else {
          return .stopped
        }
        cache[r] = kV
        cache[r].id = UUID()
        r++
        k++
      }
      guard let iV = await getItem(index: i) else {
        return .stopped
      }
      cache[r] = iV
      r++
    }
    for i in 0..<(k - start) {
      guard await enforceRunning() else {
        return .stopped
      }
      cache[i].value = 1 + i + start
      await setItem(index: i + start, value: cache[i])
      await operate()
      await (0..<i + start).concurrentForEach { [self] prev in
        await changeColor(index: prev, color: .green)
      }
      await changeColor(index: i + start, color: .red)
      await playNote(i + start)
      await delay()
      await resetColor(index: i + start)
    }
    return .finished
  }
  
  @MainActor
  @discardableResult
  @inlinable
  func mergeSort() async -> SortStatus {
    guard await enforceRunning() else {
      return .stopped
    }
    return await _mergeSort(0, data.count)
  }
}
