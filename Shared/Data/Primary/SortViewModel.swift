//
//  SortViewModel.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/2/22.
//

import Foundation
import SwiftUI
import Atomics
import CollectionConcurrencyKit

@MainActor
class SortViewModel: ObservableObject {
  var algorithm: Algorithms = .quickSort
  
  let toner = Synthesizer()
  @Published var arraySizeBacking: Float = 256.0
  var arraySize: Binding<Int>{
    Binding<Int>(get: {
      Int(self.arraySizeBacking)
    }, set: {
      self.arraySizeBacking = Float($0)
    })
  }
  @Published var data: [SortItem] = SortItem.syncSequenceOf(numItems: 256)
  @Published var operations: ManagedAtomic<Int> = ManagedAtomic(0)
  @Published var isSorted: Bool = false
  @Published var running: Bool = false
  @Published var sound: Bool = false
  @Published var delay: Float = 0.1
  @Published var showIncompleteWarning: Bool = false
  @Published var showBogoSortWarning: Bool = false
  @Published var bogoSortAccepted: Bool = false
  var sortTaskRef: Task<Void, Error>? = nil
  var recreateTaskRef: Task<Void, Error>? = nil
  
  /// Throw an unchecked error if we attempt to access a value outside the range of the `data` array's length.
  @MainActor
  @inline(__always)
  func enforceIndex(_ data: [SortItem], _ index: Int) {
    precondition(data.indices.contains(index), "The index \(index) does not exist on an array of length \(data.endIndex)!")
  }
  
  /// Check to see that the algorithm isn't stopped or the Task isn't cancelled.
  @MainActor
  @inline(__always)
  func enforceRunning() async -> Bool {
    !Task.isCancelled && running
  }
  
  /// Delay an action within an `async` closure.
  @MainActor
  @inline(__always)
  func delay() async {
    // 1 nanosecond delay; prevents the UI from freezing when all operations on the array happen at once by moving the slider to zero seconds
    try? await Task.sleep(nanoseconds: UInt64(delay > 0.0 ? delay * 1_000_000 : 1))
  }
  
  /// Play a note using the data ranges and the current delay.
  @MainActor
  @inline(__always)
  func playNote(_ index: Int) async {
    guard await enforceRunning() && sound else {
      return
    }
    await toner.playNote(value: index, range: data.indices.lowerBound...data.indices.upperBound, time: delay)
  }
  
  /// Set the contents of the data array asynchronously.
  @MainActor
  @inline(__always)
  func setData(_ data: [SortItem]) async {
    self.data = data
  }
  
  /// Increment the operation counter in the UI atomically and asynchronously.
  @MainActor
  @inline(__always)
  func operate() async {
    guard await enforceRunning() else {
      return
    }
    operations.wrappingIncrement(by: 1, ordering: .relaxed)
  }
  
  /// Get the operations counter
  @MainActor
  @inline(__always)
  func getOperations() -> Int {
    operations.load(ordering: .relaxed)
  }
  
  @MainActor
  @inline(__always)
  func setAlgo(algo: Algorithms) {
    algorithm = algo
  }
  
  /// Shuffle the array using Swift's built-in shuffle method.
  @MainActor
  @inlinable
  func shuffle() async {
    // Don't change to await enforceRunning(); will break reset function.
    guard !Task.isCancelled else {
      return
    }
    if running {
      sortTaskRef!.cancel()
    }
    data.shuffle()
  }
  
  /// Recreate the array, with a specified set of values.
  @MainActor
  @inlinable
  func recreate(numItems: Int = 128) async {
    // Don't change to await enforceRunning(); will break array size changes.
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
    data = await SortItem.sequenceOf(numItems: numItems == arraySize.wrappedValue ? numItems : arraySize.wrappedValue)
  }
  
  /// Swap the values at the firstIndex and secondIndex, with a specified delay between the two operations.
  @MainActor
  @inlinable
  func swap(_ firstIndex: Int, _ secondIndex: Int) async {
    guard await enforceRunning() else {
      return
    }
    enforceIndex(data, firstIndex)
    enforceIndex(data, secondIndex)
    await playNote(firstIndex)
    await playNote(secondIndex)
    if !running || firstIndex == secondIndex {
      return
    }
    await operate()
    await changeColor(index: firstIndex, color: .red)
    await changeColor(index: secondIndex, color: .orange)
    data.swapAt(firstIndex, secondIndex)
    await delay()
    await resetColor(index: firstIndex)
    await resetColor(index: secondIndex)
  }
  
  /// Check if the array is sorted.
  @MainActor
  @inlinable
  @discardableResult
  func isArraySorted() async -> Bool {
    guard await enforceRunning() else {
      return false
    }
    for i in 1..<data.count {
      if await !compare(firstIndex: i, secondIndex: i - 1) {
        return false
      }
    }
    return true
  }
  
  /// Get the integer value of a SortItem at the specified index.
  @MainActor
  @inline(__always)
  func getValue(index: Int) async -> Optional<Int> {
    guard await enforceRunning() else {
      return Optional.none
    }
    enforceIndex(data, index)
    await playNote(index)
    await delay()
    return data[index].value
  }
  
  /// Compare the values of two SortItems at their specified indexes.
  @MainActor
  @inlinable
  func compare(firstIndex: Int, secondIndex: Int, by: (Int, Int) -> Bool = (>=), clear: Bool = false) async -> Bool {
    guard await enforceRunning() else {
      return false
    }
    enforceIndex(data, firstIndex)
    enforceIndex(data, secondIndex)
    await changeColor(index: firstIndex, color: .blue)
    await changeColor(index: secondIndex, color: .green)
    await playNote(firstIndex)
    await playNote(secondIndex)
    guard
      let lhs = await getValue(index: firstIndex),
      let rhs = await getValue(index: secondIndex)
    else {
      return false
    }
    await operate()
    if clear {
      Task.detached { [self] in
        await delay()
        await resetColor(index: firstIndex)
        await resetColor(index: secondIndex)
      }
    }
    return by(lhs, rhs)
  }
  
  /// Change the color of a SortItem at the specified index.
  @MainActor
  @inline(__always)
  func changeColor(index: Int, color: Color) async {
    guard await enforceRunning() else {
      return
    }
    enforceIndex(data, index)
    data[index].color = color
  }
  
  /// Reset the color of a SortItem to white at the specified index.
  @MainActor
  @inline(__always)
  func resetColor(index: Int) async {
    guard await enforceRunning() else {
      return
    }
    enforceIndex(data, index)
    data[index].color = .white
  }
  
  /// Run the sorting algorithm of choice on the dataset.
  @MainActor
  @inlinable
  func doSort() async -> Bool {
    guard await enforceRunning() else {
      return false
    }
    switch algorithm {
        // Logarithmic algorithms
      case .quickSort:
        await quickSort()
      case .mergeSort:
        if await mergeSort() == .finished {
          // TODO: Send feedback in some way if the merge sort finished incorrectly?
          // Sometimes, mergesort will fail in a pretty stupid way that I can't catch consistently.
          // I know this is really hacky. But until I can find and replicate the exact bug, I can't fix it.
          if data != data.sorted() {
            print("WARN: Merge sort did not correctly sort the dataset!")
            data.sort()
          }
          let setData = await data.concurrentMap { $0.value }
          if Set(setData).count != data.count {
            print("WARN: Merge sort left a duplicate value in the dataset!")
            for i in data.indices {
              let range = data.indices
              if range.contains(i + 1) && range.contains(i) && data[i + 1].value == data[i].value {
                data[i + 1].value += 1
              }
            }
          }
        }
      case .heapSort:
        await heapSort()
        // Quadratic algorithms
      case .bubbleSort:
        await bubbleSort()
      case .selectionSort:
        await selectionSort()
      case .insertionSort:
        await insertionSort()
      case .gnomeSort:
        await gnomeSort()
      case .shakerSort:
        await shakerSort()
      case .oddEvenSort:
        await oddEvenSort()
      case .pancakeSort:
        await pancakeSort()
        // Weird algorithms
      case .bitonicSort:
        await bitonicSort()
      case .radixSort:
        await radixSort()
      case .shellSort:
        await shellSort()
      case .combSort:
        await combSort()
      case .bogoSort:
        await bogoSort()
      case .stoogeSort:
        await stoogeSort()
    }
    await isArraySorted()
    running = false
    return data == data.sorted()
  }
}
