//
//  SortViewModel.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/2/22.
//

import Foundation
import SwiftUI

class SortViewModel: ObservableObject {
    private let queue = DispatchQueue.global(qos: .utility)
    var algorithm: Algorithms = .quickSort
    
    private let toner = FMSynthesizer()
    @Published var arraySizeBacking: Float = 128.0
    var arraySize: Binding<Int>{
        Binding<Int>(get: {
            return Int(self.arraySizeBacking)
        }, set: {
            self.arraySizeBacking = Float($0)
        })
    }
    @Published var data: [SortItem] = SortView.genData(numItems: 128)
    lazy var sortableData: [SortItem] = data
    @Published var operations: Int = 0
    @Published var isSorted: Bool = false
    @Published var running: Bool = false
    @Published var sound: Bool = false
    @Published var delay: Float = 45.0
    // Last change indexes. Kinda-sorta deprecated...
    var lastSwapIndexOne: Int = -1
    var lastSwapIndexTwo: Int = -1
    var lastCompareIndexOne: Int = -1
    var lastCompareIndexTwo: Int = -1
    
    private func enforceIndex(index: Int) {
        precondition(data.indices.contains(index), "The index \(index) does not exist on an array of length \(data.endIndex)!")
    }
    
    func setAlgo(algo: Algorithms) {
        self.algorithm = algo
    }
    
    /// Shuffle the array using Swift's built-in shuffle method.
    func shuffle() {
        data.shuffle()
        sortableData = data
    }
    
    /// Recreate the array, with a specified set of values.
    func recreate(numItems: Int = 128) {
        if numItems == arraySize.wrappedValue {
            data = SortView.genData(numItems: numItems)
        } else {
            data = SortView.genData(numItems: arraySize.wrappedValue)
        }
        sortableData = data
    }
    
    /// Swap the values at the firstIndex and secondIndex, with a specified delay between the two operations.
    func swap(firstIndex: Int, secondIndex: Int) {
        let group = DispatchGroup()
        group.enter()
        enforceIndex(index: firstIndex)
        enforceIndex(index: secondIndex)
        if (lastSwapIndexOne != -1 && lastSwapIndexTwo != -1) {
            resetColor(index: lastSwapIndexOne)
            resetColor(index: lastSwapIndexTwo)
        }
        lastSwapIndexOne = firstIndex
        lastSwapIndexTwo = secondIndex
        if (sound) {
            let xFreq = calculateFrequency(index: firstIndex)
            let yFreq = calculateFrequency(index: secondIndex)
            toner.play(carrierFrequency: xFreq)
            toner.play(carrierFrequency: yFreq)
        }
        if (!running || firstIndex == secondIndex) {
            return
        }
        queue.asyncAfter(deadline: floatDelay(millis: delay + 1.0)) { [self] in
            changeColor(index: firstIndex, color: .red)
            changeColor(index: secondIndex, color: .orange)
            DispatchQueue.main.async { [self] in
                data = sortableData
            }
            sortableData.swapAt(firstIndex, secondIndex)
            resetColor(index: firstIndex)
            resetColor(index: secondIndex)
            group.leave()
        }
        group.notify(queue: queue) {
            print("Proceeding to next operation")
        }
    }
    
    /// Check if the array is sorted. Maybe deprecated.
    func isArraySorted() -> Bool {
        for i in 1..<data.count {
            if (!compare(firstIndex: i, secondIndex: i - 1)) {
                return false
            }
        }
        return true
    }
    
    /// Calculate the frequency of an array access. Deprecated.
    func calculateFrequency(index: Int) -> Float {
        enforceIndex(index: index)
        return floatRatio(
            x: Float(index),
            oldRange: 0.0...Float(data.count),
            newRange: Float(minFreq)...Float(maxFreq)
       )
    }
    
    /// Get the integer value of a SortItem at the specified index. Deprecated.
    func getValue(index: Int) -> Int {
        enforceIndex(index: index)
        toner.play(carrierFrequency: calculateFrequency(index: index))
        return data[index].value
    }
    
    /// Compare the values of two SortItems at their specified indexes. Deprecated.
    func compare(firstIndex: Int, secondIndex: Int) -> Bool {
        enforceIndex(index: firstIndex)
        enforceIndex(index: secondIndex)
        if (lastCompareIndexOne != -1 && lastCompareIndexTwo != -1) {
            resetColor(index: lastCompareIndexOne)
            resetColor(index: lastCompareIndexTwo)
        }
        lastCompareIndexOne = firstIndex
        lastCompareIndexTwo = secondIndex
        changeColor(index: firstIndex, color: .blue)
        changeColor(index: secondIndex, color: .green)
        return getValue(index: firstIndex) >= getValue(index: secondIndex)
    }
    
    /// Change the color of a SortItem at the specified index. Deprecated.
    func changeColor(index: Int, color: Color) {
        enforceIndex(index: index)
        data[index].color = color
    }
    
    /// Reset the color of a SortItem to white at the specified index. Deprecated.
    func resetColor(index: Int) {
        enforceIndex(index: index)
        data[index].color = .white
    }

    /// Run the sorting algorithm of choice on the dataset.
    func doSort() -> Bool {
        switch (algorithm) {
        case .quickSort:
            data = quickSort()
        case .bubbleSort:
            data = bubbleSort()
        case .insertionSort:
            data = insertionSort()
        case .selectionSort:
            data = selectionSort()
        case .mergeSort:
            data = emMergeSort()
        default:
            return false
        }
        return data == data.sorted()
    }
}
