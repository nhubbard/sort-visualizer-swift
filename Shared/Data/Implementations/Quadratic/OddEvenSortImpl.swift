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
        guard !Task.isCancelled else {
            return
        }
        var sorted = false
        while !sorted {
            sorted = true
            for first in [1, 0] {
                for i in stride(from: first, to: data.count - 1, by: 2) {
                    if !running {
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
