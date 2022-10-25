//
//  AttributeScopes+Extensions.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation

extension AttributeScopes: @unchecked Sendable {
  struct SortVisualizerAttributes: AttributeScope {
    let code: CodeAttributes
  }
  
  var sortVisualizerApp: SortVisualizerAttributes.Type { SortVisualizerAttributes.self }
}
