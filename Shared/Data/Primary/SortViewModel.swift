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
final class SortViewModel: ObservableObject {
  // File-specific variables
  let toner = Synthesizer()
  
  // Published sorting state variables
  @Published var arraySizeBacking: Float = Float(256)
  @Published var data: [SortItem] = SortItem.syncSequenceOf(numItems: 256)
  @Published var operations: ManagedAtomic<Int> = ManagedAtomic(0)
  @Published var isSorted: Bool = false
  @Published var running: Bool = false
  @Published var sound: Bool = false
  @Published var delay: Float = 0.1
  @Published var sizeRange: ClosedRange<Float> = 16...2048
  
  // Published UI state variables
  @Published var showIncompleteWarning: Bool = false
  @Published var showBogoSortWarning: Bool = false
  @Published var bogoSortAccepted: Bool = false
  @Published var showStepPopover: Bool = false
  // Sound error state variables
  @Published var soundDisabled: Bool = false
  @Published var showSoundError: Bool = false
  @Published var soundErrorText: String = ""
  // Bitonic sort warning
  @Published var showBitonicWarning: Bool = false
  @Published var shouldShowBitonicWarning: Bool = true
  
  // Timer
  @Published var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
  @Published var endTime: CFAbsoluteTime? = nil
  
  // Standard variables
  var algorithm: Algorithms = .quickSort
  var sortTaskRef: Task<Void, Error>? = nil
  var recreateTaskRef: Task<Void, Error>? = nil
  
  /// Throw an unchecked error if we attempt to access a value outside the range of the `data` array's length.
  @MainActor
  @inlinable
  func enforceIndex(_ index: Int) async {
    precondition(data.indices.contains(index), "The index \(index) does not exist on an array of length \(data.endIndex)!")
  }
  
  /// Throw an unchecked error if we attempt to access a value at any one of the `indices` outside the range of the `data` array's length.
  @MainActor
  @inlinable
  func enforceIndices(_ indices: Int...) async {
    await indices.concurrentForEach { [self] index in
      await enforceIndex(index)
    }
  }
  
  /// Check to see that the algorithm isn't stopped or the Task isn't cancelled.
  @MainActor
  @inlinable
  func enforceRunning() async -> Bool {
    !Task.isCancelled && running
  }
  
  /// Delay an action within an `async` closure.
  @MainActor
  @inlinable
  func delay() async {
    // 1 nanosecond delay; prevents the UI from freezing when all operations on the array happen at once by moving the slider to zero seconds
    try? await Task.sleep(nanoseconds: UInt64(max(delay * 1_000_000, 1)))
  }
  
  /// Play a note using the data ranges and the current delay.
  @MainActor
  @inlinable
  func playNote(_ index: Int) async {
    guard await enforceRunning() && sound else { return }
    await toner.playNote(value: index, range: data.indices.lowerBound...data.indices.upperBound, time: delay)
  }
  
  /// Set the contents of the data array asynchronously.
  @MainActor
  @inlinable
  func setData(_ data: [SortItem]) async {
    self.data = data
  }
  
  /// Increment the operation counter in the UI atomically and asynchronously.
  @MainActor
  @inlinable
  func operate() async {
    guard await enforceRunning() else { return }
    Task.detached { [self] in
      await operations.wrappingIncrement(by: 1, ordering: .relaxed)
    }
  }
  
  /// Get the operations counter
  @MainActor
  @inlinable
  func getOperations() -> Int {
    operations.load(ordering: .relaxed)
  }
  
  @MainActor
  @inlinable
  func getRunTime() -> String {
    if !running && endTime == nil {
      return String("0.0 sec (0.0 ops/sec)")
    } else if let endTime = endTime {
      let duration = endTime - startTime
      let perSecond = Double(getOperations()) / duration
      return String(format: "%.1f sec (%.1f ops/sec)", duration, perSecond)
    } else {
      let duration = CFAbsoluteTimeGetCurrent() - startTime
      let perSecond = Double(getOperations()) / duration
      return String(format: "%.1f sec (%.1f ops/sec)", duration, perSecond)
    }
  }
  
  @MainActor
  @inlinable
  func setAlgo(algo: Algorithms) {
    algorithm = algo
  }
  
  /// Shuffle the array using Swift's built-in shuffle method.
  @MainActor
  @inlinable
  func shuffle() async {
    // Don't change to await enforceRunning(); will break reset function.
    guard !Task.isCancelled else { return }
    if running {
      sortTaskRef!.cancel()
    }
    data.shuffle()
  }
  
  /// Recreate the array, with a specified number of values.
  @MainActor
  @inlinable
  func recreate(numItems: Int? = nil) async {
    // Don't change to await enforceRunning(); will break array size changes.
    guard !Task.isCancelled else { return }
    // Reset isSorted to false
    isSorted = false
    // Reset running to false
    if running && algorithm != .bitonicSort {
      running = false
    }
    // Reset operations counter to 0
    let _ = operations.exchange(0, ordering: .relaxed)
    // Recreate the array from scratch
    if let number = numItems {
      let size = number == Int(arraySizeBacking) ? number : Int(arraySizeBacking)
      data = await SortItem.sequenceOf(numItems: size)
    } else {
      data = await SortItem.sequenceOf(numItems: Int(arraySizeBacking))
    }
  }
  
  /// Swap the values at the firstIndex and secondIndex, with a specified delay between the two operations.
  @MainActor
  @inlinable
  func swap(_ firstIndex: Int, _ secondIndex: Int) async {
    guard await enforceRunning() && firstIndex != secondIndex else { return }
    await enforceIndices(firstIndex, secondIndex)
    await playNote(firstIndex)
    await playNote(secondIndex)
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
    guard await enforceRunning() else { return false }
    for i in 1..<data.count {
      if await !compare(i, i - 1) {
        return false
      }
    }
    return true
  }
  
  /// Compare the values of two SortItems at their specified indexes.
  @MainActor
  @inlinable
  func compare(_ firstIndex: Int, _ secondIndex: Int, by: (Int, Int) -> Bool = (>=), clear: Bool = false) async -> Bool {
    guard await enforceRunning() else { return false }
    await enforceIndices(firstIndex, secondIndex)
    await changeColor(index: firstIndex, color: .blue)
    await changeColor(index: secondIndex, color: .green)
    await playNote(firstIndex)
    await playNote(secondIndex)
    guard
      let lhs = await getValue(firstIndex),
      let rhs = await getValue(secondIndex)
    else { return false }
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
  
  /// Get the integer value of a SortItem at the specified index.
  @MainActor
  @inlinable
  func getValue(_ index: Int) async -> Int? {
    guard await enforceRunning() else { return nil }
    await enforceIndex(index)
    await playNote(index)
    await delay()
    return data[index].value
  }
  
  /// Get the SortItem from an index. Nullable.
  @MainActor
  @inlinable
  func getItem(_ index: Int) async -> SortItem? {
    guard await enforceRunning() else { return nil }
    await enforceIndex(index)
    await playNote(index)
    await delay()
    return data[index]
  }
  
  /// Set the SortItem value at an index.
  @MainActor
  @inlinable
  func setValue(_ index: Int, _ newValue: Int) async {
    guard await enforceRunning() else { return }
    await enforceIndex(index)
    await playNote(index)
    await delay()
    data[index].value = newValue
  }
  
  /// Set the SortItem at an index.
  @MainActor
  @inlinable
  func setItem(_ index: Int, _ value: SortItem) async {
    guard await enforceRunning() else { return }
    await enforceIndex(index)
    await playNote(index)
    await delay()
    data[index] = value
  }
  
  /// Change the color of a SortItem at the specified index.
  @MainActor
  @inlinable
  func changeColor(index: Int, color: Color) async {
    guard await enforceRunning() else { return }
    await enforceIndex(index)
    data[index].color = color
  }
  
  /// Reset the color of a SortItem to white at the specified index.
  @MainActor
  @inlinable
  func resetColor(index: Int) async {
    guard await enforceRunning() else { return }
    await enforceIndex(index)
    data[index].color = .white
  }
  
  /// Run the sorting algorithm of choice on the dataset.
  @MainActor
  @inlinable
  func doSort() async -> Bool {
    guard await enforceRunning() else { return false }
    endTime = nil
    startTime = CFAbsoluteTimeGetCurrent()
    switch algorithm {
      // Logarithmic algorithms
      case .quickSort:
        await quickSort()
      case .mergeSort:
        await mergeSort()
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
        if await bogoSort() == .stopped { return false }
      case .stoogeSort:
        await stoogeSort()
    }
    await isArraySorted()
    running = false
    return data == data.sorted()
  }
}
