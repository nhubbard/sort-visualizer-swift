//
//  SortItem.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/29/22.
//

import Foundation
import SwiftUI
import CollectionConcurrencyKit

struct SortItem: Identifiable, Equatable, Comparable, Hashable {
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
  
  /// Used to generate values at initialization, on array size change, and on recreation. Not parallelized for SortViewModel initializer.
  static func syncSequenceOf(numItems: Int = 128) -> [SortItem] {
    (1...numItems)
      .map {
        SortItem.fromInt(value: $0)
      }
      .shuffled()
  }
  
  /// Used to generate values at initialization, on array size change, and on recreation. Parallelized for speed.
  static func sequenceOf(numItems: Int = 128) async -> [SortItem] {
    await (1...numItems)
      .concurrentMap(useGroups: true) {
        SortItem.fromInt(value: $0)
      }
      .shuffled()
  }
  
  var id: UUID = UUID.init()
  var value: Int
  var color: Color = .white
  var width: CGFloat = 0
}
