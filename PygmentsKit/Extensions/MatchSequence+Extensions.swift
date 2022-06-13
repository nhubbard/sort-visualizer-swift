//
//  StringProtocol+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation
import Regexp

extension MatchSequence {
  public var isEmpty: Bool {
    var array: [Match] = []
    makeIterator().forEach { match in
      array.append(match)
    }
    return array.isEmpty
  }
}
