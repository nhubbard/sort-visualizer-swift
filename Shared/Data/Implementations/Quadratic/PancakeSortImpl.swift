//
//  PancakeSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func _flip(_ k: Int) async {
        guard !Task.isCancelled else {
            return
        }
        var k = k
        var left = 0
        while left < k {
            if !running {
                return
            }
            await swap(left, k)
            k--
            left++
        }
    }
    
    @MainActor
    func _maxIndex(_ k: Int) async -> Int {
        var index = 0
        for i in 0..<k {
            if await compare(firstIndex: i, secondIndex: index) {
                index = i
            }
        }
        return index
    }
    
    @MainActor
    func pancakeSort() async {
        guard !Task.isCancelled else {
            return
        }
        var n = data.count
        while n > 1 {
            if !running {
                return
            }
            let maxIndex = await _maxIndex(n)
            if maxIndex != n {
                await _flip(maxIndex)
                await _flip(n - 1)
            }
            n--
        }
    }
}
