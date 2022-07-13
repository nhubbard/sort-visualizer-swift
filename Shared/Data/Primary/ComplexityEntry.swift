//
//  ComplexityEntry.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/31/22.
//

import Foundation

struct ComplexityFile: Decodable {
  var complexities: [ComplexityEntry]
}

struct ComplexityEntry: Identifiable, Decodable {
  var key: String
  var value: String
  var mathml: String = ""
  
  var id: String { key }
}
