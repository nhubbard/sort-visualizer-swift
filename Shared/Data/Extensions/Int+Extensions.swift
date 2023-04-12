//
//  Int+Extensions.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/18/22.
//

import Foundation

// https://stackoverflow.com/a/36239949/2579761

postfix operator ++ // i++

@inlinable
@discardableResult
postfix func ++ ( left: inout Int) -> Int {
  defer {
    left &+= 1
  }
  return left
}

postfix operator -- // i--

@inlinable
@discardableResult
postfix func -- ( left: inout Int) -> Int {
  defer {
    left &-= 1
  }
  return left
}
