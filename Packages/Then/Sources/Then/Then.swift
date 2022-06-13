//
//  Then.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 6/12/22.
//

import Foundation
#if !os(Linux)
  import CoreGraphics
#endif
#if os(iOS) || os(tvOS)
  import UIKit.UIGeometry
#endif

public protocol Then {}

extension Then where Self: Any {
  /**
   * Makes the extension available to set properties with closures just after initializing and copying the value types.
   *
   * ```swift
   * let frame = CGRect().with {
   *   $0.origin.x = 10
   *   $0.size.width = 100
   * }
   * ```
   */
  @discardableResult
  @inline(__always)
  public func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
    var copy = self
    try block(&copy)
    return copy
  }
  
  /**
   * Similar to `with`. `block` is only called when `statement` returns `true`.
   *
   * ```swift
   * let isSomething = false
   * let frame = CGRect().withIf(isSomething) {
   *   $0.origin.x = 10
   *   $0.size.width = 100
   * }
   * ```
   */
  @discardableResult
  @inline(__always)
  public func withIf(_ statement: @autoclosure () -> Bool, _ block: (inout Self) throws -> Void) rethrows -> Self {
    guard statement() else {
      return self
    }
    var copy = self
    try block(&copy)
    return copy
  }
  
  /**
   * Makes it available to execute something with closures.
   *
   * ```swift
   * UserDefaults.standard.do {
   *   $0.set("example", forKey: "username")
   *   $0.set("example@example.com", forKey: "email")
   *   $0.synchronize()
   * }
   * ```
   *
   * It can also convert one type to another, like so:
   *
   * ```swift
   * let firstDateOfNextMonth: Date = Calendar(identifier: .gregorian).do {
   *   var date = $0.date(bySetting: .day, value: 1, of: Date())!
   *   date = $0.date(byAdding: .month, value: 1, to: date)!
   *   return date
   * }
   * ```
   */
  @discardableResult
  @inline(__always)
  public func `do`<T>(_ block: (Self) throws -> T) rethrows -> T {
    try block(self)
  }
  
  /**
   * Similar to `whenIf` and `do`, `block` is called only when `statement` returns `true`.
   *
   * ```swift
   * let isSomething = false
   * UserDefaults.standard.doIf(isSomething) {
   *   $0.set("example", forKey: "username")
   *   $0.set("example@example.com", forKey: "email")
   *   $0.synchronize()
   * }
   * ```
   */
  @inline(__always)
  public func doIf<T>(_ statement: @autoclosure () -> Bool, _ block: (Self) throws -> T) rethrows -> Optional<T> {
    guard statement() else {
      return Optional.none
    }
    return try Optional.some(block(self))
  }
  
  
  /**
   * Make it possible to execute a command with closures.
   *
   * ```swift
   * let synchronized: Bool = UserDefaults.standard.let {
   *   $0.set("example", forKey: "username")
   *   $0.set("example@example.com", forKey: "email")
   *   return $0.synchronize()
   * }
   * ```
   */
  @discardableResult
  @inline(__always)
  public func `let`<T>(_ block: (inout Self) throws -> T) rethrows -> T {
    var copy = self
    return try block(&copy)
  }
}

extension Then where Self: AnyObject {
  /**
   * Makes it available to set properties with closures just after initializing.
   *
   * ```swift
   * let label = UILabel().then {
   *   $0.textAlignment = .center
   *   $0.textColor = UIColor.black
   *   $0.text = "Hello, world!"
   * }
   * ```
   */
  @discardableResult
  @inline(__always)
  public func then(_ block: (Self) throws -> Void) rethrows -> Self {
    try block(self)
    return self
  }
  
  /// Similar to `then`. `block` is calling  when `statement` returns `true`.
  ///
  ///     let isSomething = false
  ///     let label = UILabel().thenIf(isSomething) {
  ///       $0.textAlignment = .center
  ///       $0.textColor = UIColor.black
  ///       $0.text = "Hello, World!"
  ///     }
  @discardableResult
  @inline(__always)
  public func thenIf(_ statement: @autoclosure () -> Bool, _ block: (Self) throws -> Void) rethrows -> Self {
    if statement() {
      try block(self)
    }
    return self
  }
}

public protocol ThenInitializer {}

extension ThenInitializer where Self: NSObject {
  /**
   * Similarly to the `then` function defined on any type, this is just syntastic sugar.
   * There are some caveats, though; see https://github.com/devxoul/Then/pull/60 for info.
   */
  @discardableResult
  @inline(__always)
  init(block: (Self) -> Void) {
    self.init()
    block(self)
  }
}

extension NSObject: Then {}

#if !os(Linux)
  extension CGPoint: Then {}
  extension CGRect: Then {}
  extension CGSize: Then {}
  extension CGVector: Then {}
#endif

extension Array: Then {}
extension Dictionary: Then {}
extension Set: Then {}
extension JSONDecoder: Then {}
extension JSONEncoder: Then {}

#if os(iOS) || os(tvOS)
  extension UIEdgeInsets: Then {}
  extension UIOffset: Then {}
  extension UIRectEdge: Then {}
#endif
