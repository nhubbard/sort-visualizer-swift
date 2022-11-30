//
//  SortItem.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/29/22.
//

import Foundation
import SwiftUI
import CollectionConcurrencyKit

struct SortItem: Identifiable, Equatable, Comparable, Hashable, @unchecked Sendable {
  static func <(lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value < rhs.value
  }
  
  static func >(lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value > rhs.value
  }
  
  static func <=(lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value <= rhs.value
  }
  
  static func >=(lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value >= rhs.value
  }
  
  static func ==(lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.id == rhs.id && lhs.value == rhs.value
  }
  
  static func fromInt(value: Int) -> SortItem {
    SortItem(value: value)
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(value)
  }
  
  // TODO: Add custom shuffles
  /// Used to generate values at initialization, on array size change, and on recreation. Not parallelized for SortViewModel initializer.
  static func syncSequenceOf(numItems: Int = 128, with method: ShuffleMethod = .random) -> [SortItem] {
    let newItems = (1...numItems)
      .map {
        SortItem.fromInt(value: $0)
      }
    // Temporary measure while other shuffles are implemented
    return newItems.shuffled()
  }
  
  // TODO: Add custom shuffles
  /// Used to generate values at initialization, on array size change, and on recreation. Parallelized for speed.
  @MainActor
  static func sequenceOf(numItems: Int = 128, with method: ShuffleMethod = .random) async -> [SortItem] {
    let newItems = await (1...numItems)
      .concurrentMap {
        SortItem.fromInt(value: $0)
      }
    // Temporary measure while other shuffles are implemented.
    return newItems.shuffled()
  }
  
  var id: UUID = UUID.init()
  var value: Int
  var color: Color = .white
  var width: CGFloat = 0
}
