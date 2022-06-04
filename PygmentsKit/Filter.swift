//
//  FilterProtocol.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

/**
 * A default filter. You must implement this protocol or use the `simpleFilter` function to create your own filter.
 */
protocol Filter {
  /// Initializer for the filter. Can be passed any number of options.
  init(options: [String: Any])
  
  /// The function that runs the filter.
  // TODO: Replace `lexer` with completed Lexer type.
  // TODO: Replace `stream` with completed Stream equivalent.
  func filter(lexer: Any, stream: Any, options: [String: Any]) throws
}

/**
 * Class used by the `simpleFilter` function to create a `Filter`.
 */
class FunctionFilter: Filter {
  var function: (Any, Any, [String: Any]) throws -> Void
  var options: [String: Any] = [:]
  
  init(function: @escaping (Any, Any, [String: Any]) throws -> Void, options: [String: Any] = [:]) {
    self.function = function
    self.options = options
  }
  
  required init(options: [String: Any] = [:]) {
    self.function = { _, _, _ in }
    self.options = options
  }
  
  // TODO: Replace Any types with appropriate actual types.
  func filter(lexer: Any, stream: Any, options: [String: Any]) throws {
    do {
      try self.function(lexer, stream, self.options)
    } catch let e {
      throw e
    }
  }
}

/**
 * The function that creates a simple filter to use.
 */
// TODO: Replace first Any w/ Lexer; replace second Any w/ stream.
func simpleFilter(options: [String: Any] = [:], filter: @escaping (Any, Any, [String: Any]) throws -> Void) rethrows -> FunctionFilter {
  return FunctionFilter(function: filter, options: options)
}
