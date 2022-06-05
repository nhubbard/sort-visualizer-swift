//
//  StringProtocol+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation
import Regex

extension MatchSequence {
  public var isEmpty: Bool {
    var array: [Match] = []
    self.makeIterator().forEach { match in
      array.append(match)
    }
    return array.isEmpty
  }
}
