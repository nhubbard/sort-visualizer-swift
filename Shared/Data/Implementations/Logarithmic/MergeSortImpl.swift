//
//  MergeSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    // Based on original inspiration (github:Myphz/sortvisualizer)
    @MainActor
    func _mergeSort(_ start: Int, _ end: Int) async {
        guard !Task.isCancelled else {
            return
        }
        if start >= end - 1 {
            return
        }
        // ~ is bitwise NOT operator; the JS version uses a unique ~~ operator for double bitwise NOT.
        let mid = start + ~(~((end - start) / 2))
        await _mergeSort(start, mid)
        await _mergeSort(mid, end)
        var cache = Array(repeating: data[0], count: end - start)
        var k = mid
        // This was previously a C-style for loop with *two* updates, written as such:
        // for (var i = start, r = 0; i < mid; r++, i++)
        var r = 0
        for i in start..<mid {
            if !running {
                return
            }
            let kVal = await getValue(index: k)!
            let iVal = await getValue(index: i)!
            while k < end && kVal < iVal {
                cache[r] = data[k]
                r++
                k++
            }
            cache[r] = data[i]
            r++
        }
        for i in 0..<(k - start) {
            if !running {
                return
            }
            data[i + start] = cache[i]
            data[i + start].value = 1 + i + start
            await changeColor(index: i + start, color: .red)
            await playNote(i + start)
            await delay()
            await resetColor(index: i + start)
        }
    }
    
    @MainActor
    func mergeSort() async {
        guard !Task.isCancelled else {
            return
        }
        await _mergeSort(0, data.count)
    }
}
