//
//  AttributeDynamicLookup+Extensions.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation

extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.SortVisualizerAttributes, T>) -> T {
    self[T.self]
  }
}
