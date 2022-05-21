//
//  Int+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/18/22.
//

import Foundation

postfix operator ++ // i++
@discardableResult postfix func ++ ( left: inout Int) -> Int {
   defer {left += 1}
   return left
}

postfix operator -- // i--
@discardableResult postfix func -- ( left: inout Int) -> Int {
   defer {left -= 1}
   return left
}
