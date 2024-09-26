//
//  AttributeDynamicLookup+Extensions.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation

extension KeyPath: @unchecked @retroactive Sendable {}

extension AttributeDynamicLookup: @unchecked @retroactive Sendable {
  subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.SortSymphonyAttributes, T>) -> T {
    self[T.self]
  }
}
