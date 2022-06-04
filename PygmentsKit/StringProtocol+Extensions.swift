//
//  StringProtocol+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

extension StringProtocol {
  func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
    var result: [Range<Index>] = []
    var startIndex = self.startIndex
    while startIndex < endIndex,
          let range = self[startIndex...].range(of: string, options: options) {
      result.append(range)
      startIndex = range.lowerBound < range.upperBound ? range.upperBound :
      index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
    }
    return result
  }
}
