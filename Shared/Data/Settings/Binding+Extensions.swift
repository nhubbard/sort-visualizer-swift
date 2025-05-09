//
//  Binding+Extensions.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 1/10/23.
//

import Foundation
import SwiftUI

/// https://stackoverflow.com/a/74356845/2579761
public extension Binding {
  static func convert<TInt: Sendable, TFloat: Sendable>(from intBinding: Binding<TInt>) -> Binding<TFloat>
    where TInt: BinaryInteger, TFloat: BinaryFloatingPoint {
    Binding<TFloat>(
      get: { TFloat(intBinding.wrappedValue) },
      set: { intBinding.wrappedValue = TInt($0) }
    )
  }

  static func convert<TFloat: Sendable, TInt: Sendable>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
    where TFloat: BinaryFloatingPoint, TInt: BinaryInteger {
    Binding<TInt>(
      get: { TInt(floatBinding.wrappedValue) },
      set: { floatBinding.wrappedValue = TFloat($0) }
    )
  }
}
