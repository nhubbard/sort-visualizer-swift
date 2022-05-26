//
//  OddEvenSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func oddEvenSort() async {
        guard await enforceRunning() else {
            return
        }
        var sorted = false
        while !sorted {
            guard await enforceRunning() else {
                return
            }
            sorted = true
            for first in [1, 0] {
                guard await enforceRunning() else {
                    return
                }
                for i in stride(from: first, to: data.count - 1, by: 2) {
                    guard await enforceRunning() else {
                        return
                    }
                    if await compare(firstIndex: i, secondIndex: i + 1) {
                        await swap(i, i + 1)
                        sorted = false
                    }
                }
            }
        }
    }
}
