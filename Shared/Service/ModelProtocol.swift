//
//  ModelProtocol.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 2/19/24.
//

import Foundation
import SwiftUI

protocol ModelProtocol {
    /// Throw an unchecked error if we attempt to access a value outside the range of the `data` array's length.
    func enforceIndex(_ index: Int) async

    /// Throw an unchecked error if we attempt to access a value at any one of the `indices` outside the range of the
    /// `data` array's length.
    func enforceIndices(_ indices: Int...) async

    /// Check to see that the algorithm isn't stopped or the Task isn't cancelled.
    func enforceRunning() async -> Bool

    /// Delay an action within an `async` closure.
    func delay() async

    /// Play a note using the data ranges and the current delay.
    func playNote(_ index: Int) async

    /// Set the contents of the data array asynchronously.
    func setData(_ data: [SortItem]) async

    /// Increment the operation counter in the UI atomically and asynchronously.
    func operate() async

    /// Get the operations counter
    func getOperations() async -> Int

    func getRunTime() async -> String

    func setAlgo(algo: Algorithms) async

    /// Shuffle the array using Swift's built-in shuffle method.
    func shuffle() async

    /// Recreate the array, with a specified number of values.
    func recreate(numItems: Int?) async

    /// Swap the values at the firstIndex and secondIndex, with a specified delay between the two operations.
    func swap(_ firstIndex: Int, _ secondIndex: Int) async

    /// Check if the array is sorted.
    @discardableResult
    func isArraySorted() async -> Bool

    /// Compare the values of two SortItems at their specified indexes.
    func compare(_ firstIndex: Int, _ secondIndex: Int, by: (Int, Int) -> Bool, clear: Bool, count: Bool) async -> Bool

    /// Get the integer value of a SortItem at the specified index.
    func getValue(_ index: Int) async -> Int?

    /// Get the SortItem from an index. Nullable.
    func getItem(_ index: Int) async -> SortItem?

    /// Set the SortItem value at an index.
    func setValue(_ index: Int, _ newValue: Int) async

    /// Set the SortItem at an index.
    func setItem(_ index: Int, _ value: SortItem) async

    /// Change the color of a SortItem at the specified index.
    func changeColor(index: Int, color: Color) async

    /// Reset the color of a SortItem to white at the specified index.
    func resetColor(index: Int) async

    /// Run the sorting algorithm of choice on the dataset.
    func doSort() async -> Bool
}
