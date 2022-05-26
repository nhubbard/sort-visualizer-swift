//
//  StoogeSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func _stoogeSort(_ start: Int, _ end: Int) async {
        guard await enforceRunning() else {
            return
        }
        let len = end - start + 1
        if len <= 1 {
            return
        } else if len == 2 {
            let startValue = await getValue(index: start)!
            let endValue = await getValue(index: end)!
            if startValue > endValue {
                await swap(start, end)
            }
            return
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
