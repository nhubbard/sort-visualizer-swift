//
//  SortItem.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 4/29/22.
//

import Foundation
import SwiftUI

@frozen public struct SortItem: Identifiable, Equatable, Comparable, Hashable, Sendable {
  public static func < (lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value < rhs.value
  }

  public static func > (lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value > rhs.value
  }

  public static func <= (lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value <= rhs.value
  }

  public static func >= (lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.value >= rhs.value
  }

  public static func == (lhs: SortItem, rhs: SortItem) -> Bool {
    lhs.id == rhs.id && lhs.value == rhs.value && lhs.color == rhs.color
  }

  public static func fromInt(value: Int) -> SortItem {
    SortItem(value: value)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(value)
    hasher.combine(color.hashValue)
  }

  public var id: UUID = UUID.init()
  public var value: Int
  public var color: Color = .white
  public var width: CGFloat = 0
}