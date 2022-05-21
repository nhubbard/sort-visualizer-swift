//
//  RadixSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation
import SwiftUI
import CollectionConcurrencyKit

extension SortViewModel {
    @MainActor
    func radixSort() async {
        guard !Task.isCancelled else {
            return
        }
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple, .teal, .cyan, .mint, .pink].shuffled()
        let base = colors.count
        var done = false
        var digits = 1
        while !done {
            done = true
            var buckets: [[SortItem]] = .init(repeating: [], count: base)
            data.forEach { number in
                let remainingPart = number.value / digits
                let digit = remainingPart % base
                buckets[digit].append(number)
                if remainingPart > 0 {
                    done = false
                }
            }
            digits *= base
            var counter = 0
            var colorSequence = colors.cycle()
            for bucket in buckets {
                let color = colorSequence.next()!
                var coloredIndices: [Int] = []
                for item in bucket {
                    var newItem = item
                    newItem.id = UUID.init()
                    data[counter] = newItem
                    await changeColor(index: counter, color: color)
                    coloredIndices.append(counter)
                    counter++
                    await delay()
                }
                await delay()
                await coloredIndices.concurrentForEach { [self] index in
                    await resetColor(index: index)
                }
                coloredIndices.removeAll()
            }
            counter = 0
            await delay()
        }
    }
}
