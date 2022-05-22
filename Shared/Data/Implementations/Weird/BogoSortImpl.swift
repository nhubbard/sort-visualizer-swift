//
//  BogoSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func _shuffleBogo() async {
        guard !Task.isCancelled else {
            return
        }
        for i in 0..<data.count {
            await swap(i, Int.random(in: data.indices))
            await delay()
        }
    }
    
    @MainActor
    func bogoSort() async {
        guard !Task.isCancelled else {
            return
        }
        while data != data.sorted() {
            if !running {
                return
            }
            await _shuffleBogo()
        }
    }
}
