//
//  BubbleSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    // Based on inspiration (github:Myphz/sortvisualizer)
    @MainActor
    func bubbleSort() async {
        guard !Task.isCancelled else {
            return
        }
        for i in 1..<data.count {
            for j in 0..<(data.count - i) {
                if !running {
                    return
                }
                if await compare(firstIndex: j, secondIndex: j + 1) {
                    await swap(j, j + 1)
                }
            }
        }
    }
}
