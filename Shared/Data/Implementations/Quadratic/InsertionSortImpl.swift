//
//  InsertionSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    // This is the one algorithm that I didn't rewrite following the JS implementation; it ended up taking 400x longer and required a ton of iterations and concurrency helpers.
    @MainActor
    func insertionSort() async {
        guard await enforceRunning() else {
            return
        }
        while data != data.sorted() {
            guard await enforceRunning() else {
                return
            }
            for i in 1..<data.count {
                guard await enforceRunning() else {
                    return
                }
                var j = i
                while j > 0 {
                    guard await enforceRunning() else {
                        return
                    }
                    if data[j] < data[j - 1] {
                        await swap(j, j - 1)
                    }
                    j--
                }
            }
        }
    }
}
