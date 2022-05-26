//
//  BitonicSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func bitonicSort() async {
        guard await enforceRunning() else {
            return
        }
        let n = data.count
        var k = 2
        while k <= n {
            guard await enforceRunning() else {
                return
            }
            var j = Int(floor(Double(k / 2)))
            while j > 0 {
                guard await enforceRunning() else {
                    return
                }
                for i in 0..<n {
                    guard await enforceRunning() else {
                        return
                    }
                    let l = i ^ j
                    if l > i {
                        let comp = await compare(firstIndex: i, secondIndex: l)
                        if (i & k) == 0 && comp || (i & k) != 0 && (!comp) {
                            await swap(i, l)
                        }
                    }
                }
                j = Int(floor(Double(j / 2)))
            }
            k *= 2
        }
    }
}
