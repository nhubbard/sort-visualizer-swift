//
//  Array+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/11/22.
//

import Foundation

extension SortViewModel {
    /// A naive bubble sort implementation. Thanks to: https://medium.com/@EnnioMa/back-to-the-fundamentals-sorting-algorithms-in-swift-from-scratch-fccf8a3daea3
    @MainActor
    func bubbleSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        for i in 0..<(data.count - 1) {
            for j in 0..<(data.count - i - 1) where areInIncreasingOrder(data[j + 1], data[j]) {
                // theData.swapAt(j, j + 1)
                await swap(j, j + 1)
            }
        }
        return data
    }
    
    /// A naive insertion sort implementation.
    @MainActor
    func insertionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        var theData = self.data
        for i in 1..<theData.count {
            let key = theData[i]
            var j = i - 1
            while j >= 0 && areInIncreasingOrder(key, theData[j]) {
                theData[j+1] = theData[j]
                j = j - 1
            }
            theData[j + 1] = key
        }
        return theData
    }
    
    /// A naive selection sort implementation.
    @MainActor
    func selectionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        for i in 0..<(data.count-1) {
            var key = i
            for j in i+1..<data.count where areInIncreasingOrder(data[j], data[key]) {
                key = j
            }
            guard i != key else { continue }
            // data.swapAt(i, key)
            await swap(i, key)
        }
        return data
    }
    
    /// A naive mergesort implementation.
    @MainActor
    private func merge(left: [SortItem], right: [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> Optional<[SortItem]> {
        guard !Task.isCancelled else {
            return Optional.none
        }
        var output: [SortItem] = []
        var mutableLeft = left
        var mutableRight = right
        while mutableLeft.count > 0 && mutableRight.count > 0 {
            if let firstElement = mutableLeft.first, let secondElement = mutableRight.first {
                if !areInIncreasingOrder(firstElement, secondElement) {
                    output.append(secondElement)
                    mutableRight.remove(at: 0)
                } else {
                    output.append(firstElement)
                    mutableLeft.remove(at: 0)
                }
            }
        }
        output.append(contentsOf: mutableLeft)
        output.append(contentsOf: mutableRight)
        return output
    }
    
    @MainActor
    private func _emMergeSort(data: [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        if data.count < 2 { return data }
        let leftArray = Array(data[..<Int(data.count / 2)])
        let rightArray = Array(data[Int(data.count / 2)..<data.count])
        let result = await merge(left: await _emMergeSort(data: leftArray, by: areInIncreasingOrder), right: _emMergeSort(data: rightArray, by: areInIncreasingOrder), by: areInIncreasingOrder)
        return result ?? data
    }
    
    @MainActor
    func emMergeSort(by: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        return await _emMergeSort(data: data, by: by)
    }
    
    /// A naive quicksort implementation.
    @MainActor
    private func _quickSort(_ array: inout [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        if array.count < 2 { return array }
        var data = array
        let pivot = data.remove(at: 0)
        var left = data.filter { areInIncreasingOrder($0, pivot) }
        var right = data.filter { !areInIncreasingOrder($0, pivot) }
        let middle = [pivot]
        let lhs = await _quickSort(&left, by: areInIncreasingOrder)
        let rhs = await _quickSort(&right, by: areInIncreasingOrder)
        return lhs + middle + rhs
    }
    
    @MainActor
    func quickSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async -> [SortItem] {
        guard !Task.isCancelled else {
            return data
        }
        var myData = data
        return await _quickSort(&myData, by: areInIncreasingOrder)
    }
}
