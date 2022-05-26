//
//  CombSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func combSort() async {
        guard await enforceRunning() else {
            return
        }
        let length = data.count
        let shrink = 1.3
        var gap = length
        var sorted = false
        while !sorted {
            guard await enforceRunning() else {
                return
            }
            gap = Int(Double(gap) / shrink)
            if gap <= 1 {
                sorted = true
                gap = 1
            }
            for i in 0..<(length - gap) {
                guard await enforceRunning() else {
                    return
                }
                let sm = gap + i
                if await compare(firstIndex: i, secondIndex: sm) {
                    await swap(i, sm)
                    sorted = false
                }
            }
        }
    }
}
