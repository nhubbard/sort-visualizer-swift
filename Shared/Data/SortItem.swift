//
//  SortItem.swift
//  Sort2
//
//  Created by Nicholas Hubbard on 4/29/22.
//

import Foundation
import SwiftUI

struct SortItem: Identifiable, Equatable, Comparable, Hashable {
    static func <(lhs: SortItem, rhs: SortItem) -> Bool {
        return lhs.value < rhs.value
    }
    
    static func >(lhs: SortItem, rhs: SortItem) -> Bool {
        return lhs.value > rhs.value
    }
    
    static func <=(lhs: SortItem, rhs: SortItem) -> Bool {
        return lhs.value <= rhs.value
    }
    
    static func >=(lhs: SortItem, rhs: SortItem) -> Bool {
        return lhs.value >= rhs.value
    }
    
    static func ==(lhs: SortItem, rhs: SortItem) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
    
    static func fromInt(value: Int) -> SortItem {
        return SortItem(value: value)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(value)
    }
    
    var id: UUID = UUID.init()
    var value: Int
    var color: Color = .white
    var width: CGFloat = 0
}
