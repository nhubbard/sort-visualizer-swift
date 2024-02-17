//
//  Scene+ContentSize.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 2/16/24.
//

import Foundation
import SwiftUI

extension Scene {
  func windowResizabilityContentSize() -> some Scene {
    if #available(macOS 13.0, *) {
      return windowResizability(.contentMinSize)
    } else {
      return self
    }
  }
}
