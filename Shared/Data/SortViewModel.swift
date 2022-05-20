//
//  SortViewModel.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/2/22.
//

import Foundation
import SwiftUI
import Atomics

@MainActor
class SortViewModel: ObservableObject {
    var algorithm: Algorithms = .quickSort
    
    let toner = FMSynthesizer()
    @Published var arraySizeBacking: Float = 128.0
    var arraySize: Binding<Int>{
        Binding<Int>(get: {
            return Int(self.arraySizeBacking)
        }, set: {
            self.arraySizeBacking = Float($0)
        })
    }
    @Published var data: [SortItem] = SortItem.syncSequenceOf(numItems: 128)
    @Published var operations: ManagedAtomic<Int> = ManagedAtomic(0)
    @Published var isSorted: Bool = false
    @Published var running: Bool = false
    @Published var sound: Bool = false
    @Published var delay: Float = 0.1
    var sortTaskRef: Task<Void, Error>? = nil
    var recreateTaskRef: Task<Void, Error>? = nil
    
    /// Throw an unchecked error if we attempt to access a value outside the range of the `data` array's length.
    @MainActor
    func enforceIndex(_ data: [SortItem], _ index: Int) {
        precondition(data.indices.contains(index), "The index \(index) does not exist on an array of length \(data.endIndex)!")
    }
    
    /// Set the contents of the data array asynchronously.
    @MainActor
    func setData(_ data: [SortItem]) async {
        self.data = data
    }
    
    /// Increment the operation counter in the UI atomically and asynchronously.
    @MainActor
    func operate() async {
        guard !Task.isCancelled else {
            return
        }
        operations.wrappingIncrement(by: 1, ordering: .relaxed)
    }
    
    /// Get the operations counter
    @MainActor
    func getOperations() -> Int {
        return operations.load(ordering: .relaxed)
    }
    
    @MainActor
    func setAlgo(algo: Algorithms) {
        self.algorithm = algo
    }
    
    /// Shuffle the array using Swift's built-in shuffle method.
    @MainActor
    func shuffle() async {
        guard !Task.isCancelled else {
            return
        }
        if (running) {
            sortTaskRef!.cancel()
        }
        await MainActor.run {
            data.shuffle()
        }
    }
    
    /// Recreate the array, with a specified set of values.
    @MainActor
    func recreate(numItems: Int = 128) async {
        guard !Task.isCancelled else {
            return
        }
        // Reset isSorted to false
        isSorted = false
        // Reset running to false
        running = false
        // Reset operations counter to 0
        let _ = operations.exchange(0, ordering: .relaxed)
        // Recreate the array from scratch
        if numItems == arraySize.wrappedValue {
            data = await SortItem.sequenceOf(numItems: numItems)
        } else {
            data = await SortItem.sequenceOf(numItems: arraySize.wrappedValue)
        }
    }
    
    /// Swap the values at the firstIndex and secondIndex, with a specified delay between the two operations.
    @MainActor
    func swap(_ firstIndex: Int, _ secondIndex: Int) async {
        guard !Task.isCancelled else {
            return
        }
        let delayNs = UInt64(delay * 1_000_000)
        enforceIndex(data, firstIndex)
        enforceIndex(data, secondIndex)
        if (sound) {
            let xFreq = await calculateFrequency(index: firstIndex)
            let yFreq = await calculateFrequency(index: secondIndex)
            toner.play(carrierFrequency: xFreq)
            toner.play(carrierFrequency: yFreq)
        }
        if (!running || firstIndex == secondIndex) {
            return
        }
        await operate()
        await changeColor(index: firstIndex, color: .red)
        await changeColor(index: secondIndex, color: .orange)
        data.swapAt(firstIndex, secondIndex)
        try? await Task.sleep(nanoseconds: delayNs)
        await resetColor(index: firstIndex)
        await resetColor(index: secondIndex)
    }
    
    /// Check if the array is sorted.
    @MainActor
    func isArraySorted() async -> Bool {
        guard !Task.isCancelled else {
            return false
        }
        for i in 1..<data.count {
            do {
                if (try await !compare(firstIndex: i, secondIndex: i - 1)) {
                    return false
                }
            } catch _ {
                return false
            }
        }
        return true
    }
    
    /// Calculate the frequency of an array access.
    @MainActor
    func calculateFrequency(index: Int) async -> Float {
        guard !Task.isCancelled else {
            return Float(minFreq)
        }
        enforceIndex(data, index)
        return floatRatio(
            x: Float(index),
            oldRange: 0.0...Float(data.count),
            newRange: Float(minFreq)...Float(maxFreq)
       )
    }
    
    /// Get the integer value of a SortItem at the specified index.
    @MainActor
    func getValue(index: Int) async -> Optional<Int> {
        guard !Task.isCancelled else {
            return Optional.none
        }
        enforceIndex(data, index)
        if (sound) {
            toner.play(carrierFrequency: await calculateFrequency(index: index))
        }
        let delayNs = UInt64(delay * 1_000_000)
        try? await Task.sleep(nanoseconds: delayNs)
        return data[index].value
    }
    
    /// Compare the values of two SortItems at their specified indexes.
    @MainActor
    func compare(firstIndex: Int, secondIndex: Int, by: ((Int, Int) -> Bool) = (>=)) async throws -> Bool {
        guard !Task.isCancelled else {
            throw TaskCancelledError()
        }
        enforceIndex(data, firstIndex)
        enforceIndex(data, secondIndex)
        await changeColor(index: firstIndex, color: .blue)
        await changeColor(index: secondIndex, color: .green)
        guard
            let lhs = await getValue(index: firstIndex),
            let rhs = await getValue(index: secondIndex)
        else {
            throw TaskCancelledError()
        }
        await operate()
        return by(lhs, rhs)
    }
    
    /// Moves a value at index `j` right. Used by insertion sort.
    @MainActor
    func shiftRight(_ data: inout [SortItem], _ j: inout Int) async {
        guard !Task.isCancelled else {
            return
        }
        data[j + 1] = data[j]
        j -= 1
    }
    
    /// Change the color of a SortItem at the specified index.
    @MainActor
    func changeColor(index: Int, color: Color) async {
        guard !Task.isCancelled else {
            return
        }
        enforceIndex(data, index)
        data[index].color = color
    }
    
    /// Reset the color of a SortItem to white at the specified index.
    @MainActor
    func resetColor(index: Int) async {
        guard !Task.isCancelled else {
            return
        }
        enforceIndex(data, index)
        data[index].color = .white
    }

    /// Run the sorting algorithm of choice on the dataset.
    @MainActor
    func doSort() async -> Bool {
        func innerDoSort(_ algorithm: Algorithms) async -> Optional<[SortItem]> {
            switch (algorithm) {
                // Logarithmic algorithms
                case .quickSort:
                    _ = await quickSort()
                    return data
                case .mergeSort:
                    _ = await mergeSort()
                    return data
                case .heapSort:
                    await heapSort()
                    return data
                case .bubbleSort:
                    return await bubbleSort()
                case .insertionSort:
                    return await insertionSort()
                case .selectionSort:
                    return await selectionSort()
                default:
                    return Optional.none
            }
        }
        guard !Task.isCancelled else {
            return false
        }
        guard
            let result = await innerDoSort(self.algorithm),
            result != Optional.none
        else {
            return false
        }
        if algorithm != .quickSort && algorithm != .mergeSort {
            await setData(result)
        }
        // FIXME: This is a hacky workaround for a bug in Merge Sort. I can't figure out exactly why, but when this bug happens, the debugger always prints a warning about having a duplicate item in it that it "will cause issues".
        if algorithm == .mergeSort {
            data = Array(Set(data)).sorted()
        }
        let _ = await isArraySorted()
        running = false
        return data == data.sorted()
    }
}
