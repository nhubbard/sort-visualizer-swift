//
//  CodeThemes.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 12/10/22.
//

import Foundation

@frozen public enum CodeThemes: Int, Sendable {
  case monokai = 0
  case pygments
  case arduino
  case colorful
  case dracula
  case emacs
  
  var name: String {
    switch self {
      case .monokai:
        return "Monokai"
      case .pygments:
        return "Pygments"
      case .arduino:
        return "Arduino"
      case .colorful:
        return "Colorful"
      case .dracula:
        return "Dracula"
      case .emacs:
        return "Emacs"
    }
  }
  
  static func fromInt(_ value: Int) -> CodeThemes {
    switch value {
      case 0:
        return .monokai
      case 1:
        return .pygments
      case 2:
        return .arduino
      case 3:
        return .colorful
      case 4:
        return .dracula
      case 5:
        return .emacs
      default:
        return .monokai
    }
  }
}
