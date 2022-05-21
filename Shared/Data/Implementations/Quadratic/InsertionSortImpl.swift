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
    func selectionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async {
        guard !Task.isCancelled else {
            return
        }
        for i in 0..<(data.count-1) {
            var key = i
            for j in i+1..<data.count where await compare(firstIndex: key, secondIndex: j) {
                key = j
            }
            guard i != key else { continue }
            await delay()
            await swap(i, key)
        }
    }
}
