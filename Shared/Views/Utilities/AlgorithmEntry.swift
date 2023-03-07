//
//  AlgorithmEntry.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/28/22.
//

import Foundation
import SwiftUI

@frozen public struct AlgorithmEntry: Hashable, Equatable {
  public static func == (lhs: AlgorithmEntry, rhs: AlgorithmEntry) -> Bool {
    lhs.id == rhs.id && lhs.name == rhs.name && lhs.icon == rhs.icon && lhs.tag == rhs.tag
  }

  public var id: UUID = .init()
  public var name: String
  public var icon: String
  public var destination: AnyView
  public var tag: Int

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(icon)
    hasher.combine(tag)
  }
}
