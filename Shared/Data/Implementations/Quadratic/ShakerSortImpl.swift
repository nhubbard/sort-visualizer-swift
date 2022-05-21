//
//  ShakerSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func shakerSort() async {
        guard !Task.isCancelled else {
            return
        }
        var sorted = true
        while sorted {
            for i in 0..<(data.count - 1) {
                if !running {
                    return
                }
                if await compare(firstIndex: i, secondIndex: i + 1) {
                    await swap(i, i + 1)
                    sorted = true
                }
            }
            if !sorted {
                break
            }
            sorted = false
            for j in (1..<(data.count - 1)).reversed() {
                if !running {
                    return
                }
                if await compare(firstIndex: j - 1, secondIndex: j) {
                    await swap(j - 1, j)
                    sorted = true
                }
            }
        }
    }
}
