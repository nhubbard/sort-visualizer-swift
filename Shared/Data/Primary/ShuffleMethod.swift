//
//  Shuffle.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 11/11/22.
//

import Foundation
import CollectionConcurrencyKit

private func genShuffledN(power: Double, size: Int = 256) -> [Int] {
  var out = [Int](repeating: 0, count: size)
  for i in out.indices {
    // Normalize to [-1, +1]
    let x: Double = (2.0 * Double(i) / Double(size)) - 1.0
    // Calculate x^power
    let v: Double = pow(x, power)
    // Normalize to array size
    let w: Double = ((v + 1.0) / 2.0 * Double(size) + 1.0)
    // Set values
    out[i] = Int(w) + 1
  }
  return out
}

enum ShuffleMethod: Int {
  case random = 0
  case ascending
  case descending
  case shuffledCubic
  case shuffledQuintic
  
  static func fromInt(_ value: Int) -> ShuffleMethod {
    switch value {
      case 0:
        return .random
      case 1:
        return .ascending
      case 2:
        return .descending
      case 3:
        return .shuffledCubic
      case 4:
        return .shuffledQuintic
      default:
        return .random
    }
  }
  
  /// Create an array of numbers, shuffled using the defined method. Synchronous.
  /// - Parameter method: The method to shuffle with.
  /// - Parameter maximum: The largest number in the sequence.
  /// - Returns: An array of `SortItem`s, with their values shuffled according to the chosen method.
  static func createSync(method: ShuffleMethod = .random, maximum: Int = 256) -> [SortItem] {
    switch method {
      case .random:
        return (1...maximum).map { SortItem.fromInt(value: $0) }.shuffled()
      case .ascending:
        return (1...maximum).map { SortItem.fromInt(value: $0) }
      case .descending:
        return (1...maximum).map { SortItem.fromInt(value: $0) }.reversed()
      case .shuffledCubic:
        return genShuffledN(power: 3, size: maximum).map { SortItem.fromInt(value: $0) }.shuffled()
      case .shuffledQuintic:
        return genShuffledN(power: 5, size: maximum).map { SortItem.fromInt(value: $0) }.shuffled()
    }
  }
  
  /// Create an array of numbers, shuffled using the defined method. Parallel asynchronous. Isolated to main actor, because that's the only place this function is used.
  /// - Parameter method: The method to shuffle with.
  /// - Parameter maximum: The largest number in the sequence.
  /// - Returns: An array of `SortItem`s, with their values shuffled according to the chosen method.
  @MainActor
  static func create(method: ShuffleMethod = .random, maximum: Int = 256) async -> [SortItem] {
    switch method {
      case .random:
        return await (1...maximum).concurrentMap { SortItem.fromInt(value: $0) }.shuffled()
      case .ascending:
        return await (1...maximum).concurrentMap { SortItem.fromInt(value: $0) }
      case .descending:
        return await (1...maximum).concurrentMap { SortItem.fromInt(value: $0) }.reversed()
      case .shuffledCubic:
        return await genShuffledN(power: 3, size: maximum).concurrentMap { SortItem.fromInt(value: $0) }.shuffled()
      case .shuffledQuintic:
        return await genShuffledN(power: 5, size: maximum).concurrentMap { SortItem.fromInt(value: $0) }.shuffled()
    }
  }
}
