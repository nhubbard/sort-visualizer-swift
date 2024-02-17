//
//  AttributeScopes+Extensions.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation

extension AttributeScopes: @unchecked Sendable {
  struct SortSymphonyAttributes: AttributeScope {
    let code: CodeAttributes
  }

  var sortSymphonyApp: SortSymphonyAttributes.Type { SortSymphonyAttributes.self }
}
