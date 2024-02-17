//
//  CodeTheme.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI

protocol CodeTheme {
  func getBgColor() -> Color
  func getFormat(token: CodeAttributes.Value) -> TextFormat
}
