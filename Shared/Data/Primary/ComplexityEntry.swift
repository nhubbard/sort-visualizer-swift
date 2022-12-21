//
//  ComplexityEntry.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/31/22.
//

import Foundation

@frozen public struct ComplexityFile: Decodable, Sendable {
  public var complexities: [ComplexityEntry]
}

@frozen public struct ComplexityEntry: Identifiable, Decodable, Sendable {
  public var key: String
  public var value: String
  public var mathml: String = ""
  
  public var id: String { key }
}
