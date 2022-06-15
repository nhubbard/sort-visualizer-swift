//
//  ShellSortImpl.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
  @MainActor
  func shellSort() async {
    guard await enforceRunning() else {
      return
    }
    let n = data.count
    var interval = ~(~(n / 2))
    var j: Int
    while interval > 0 {
      guard await enforceRunning() else {
        return
      }
      for i in interval..<n {
        guard await enforceRunning() else {
          return
        }
        let temp = data[i]
        j = i
        let value = await getValue(index: j - interval)!
        while j >= interval && value > temp.value {
          guard await enforceRunning() else {
            return
          }
          await swap(j, j - interval)
          await changeColor(index: j, color: .red)
          data[j].value = j + 1
          await playNote(j)
          await delay()
          await resetColor(index: j)
          j -= interval
        }
        await operate()
        data[j] = temp
        data[j].value = j + 1
        await playNote(j)
        await changeColor(index: j, color: .blue)
        await delay()
        await resetColor(index: j)
      }
      interval = ~(~(interval / 2))
    }
  }
}
