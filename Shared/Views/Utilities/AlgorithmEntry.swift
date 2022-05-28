//
//  AlgorithmEntry.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import Foundation
import SwiftUI

struct AlgorithmEntry: Hashable, Equatable {
    static func == (lhs: AlgorithmEntry, rhs: AlgorithmEntry) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.icon == rhs.icon && lhs.tag == rhs.tag
    }
    
    var id: UUID = .init()
    var name: String
    var icon: String
    var destination: AnyView
    var tag: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(icon)
        hasher.combine(tag)
    }
}
