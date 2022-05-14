//
//  Array+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/11/22.
//

import Foundation

extension SortViewModel {
    /// A naive bubble sort implementation. Thanks to: https://medium.com/@EnnioMa/back-to-the-fundamentals-sorting-algorithms-in-swift-from-scratch-fccf8a3daea3
    func bubbleSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
        for i in 0..<(data.count - 1) {
            for j in 0..<(data.count - i - 1) where areInIncreasingOrder(data[j + 1], data[j]) {
                // theData.swapAt(j, j + 1)
                swap(firstIndex: j, secondIndex: j + 1)
            }
        }
        return data
    }
    
    /// A naive insertion sort implementation.
    func insertionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
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
    func selectionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
        for i in 0..<(data.count-1) {
            var key = i
            for j in i+1..<data.count where areInIncreasingOrder(data[j], data[key]) {
                key = j
            }
            guard i != key else { continue }
            // data.swapAt(i, key)
            swap(firstIndex: i, secondIndex: key)
        }
        return data
    }
    
    /// A naive mergesort implementation.
    private func merge(left: [SortItem], right: [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
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
     
    private func _emMergeSort(data: [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
        if data.count < 2 { return data }
        
        let leftArray = Array(data[..<Int(data.count / 2)])
        let rightArray = Array(data[Int(data.count / 2)..<data.count])
        return merge(left: _emMergeSort(data: leftArray, by: areInIncreasingOrder), right: _emMergeSort(data: rightArray, by: areInIncreasingOrder), by: areInIncreasingOrder)
    }
    
    func emMergeSort(by: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
        return _emMergeSort(data: data, by: by)
    }
    
    /// A naive quicksort implementation.
    private func _quickSort(_ array: inout [SortItem], by areInIncreasingOrder: ((SortItem, SortItem) -> Bool)) -> [SortItem] {
        if array.count < 2 { return array }
        var data = array
        let pivot = data.remove(at: 0)
        var left = data.filter { areInIncreasingOrder($0, pivot) }
        var right = data.filter { !areInIncreasingOrder($0, pivot) }
        let middle = [pivot]
        return _quickSort(&left, by: areInIncreasingOrder) + middle + _quickSort(&right, by: areInIncreasingOrder)
    }
    
    func quickSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) -> [SortItem] {
        return _quickSort(&data, by: areInIncreasingOrder)
    }
}
