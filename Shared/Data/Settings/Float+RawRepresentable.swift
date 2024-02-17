//
//  Float+RawRepresentable.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 1/1/23.
//

import Foundation

/// A RawRepresentable implementation for the built-in Float type, which allows for Float values to be used with
/// @AppStorage.
extension Float: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8) else {
      return nil
    }
    do {
      let result = try JSONDecoder().decode(Float.self, from: data)
      self = result
    } catch {
      return nil
    }
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8) else {
      return "0.0"
    }
    return result
  }
}
