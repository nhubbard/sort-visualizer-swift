//
//  DefaultStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI
import Then

/// The default style. Inspired by Emacs 22.
struct DefaultStyle: BaseStyle {
  /// The name of this style.
  var name: String = "default"
  
  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: 0xf8f8f8)
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    return TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .whitespace:
          it.fg(0xbbbbbb)
        case .comment:
          it.fg(0x3d7b7b).italic()
        case .commentPreproc:
          it.fg(0x9c6500)
        case .keyword, .nameTag:
          it.fg(0x008000)
        case .keywordType:
          it.fg(0xb00040)
        case .operator, .number, .numberInteger, .numberIntegerLong, .numberBin, .numberHex, .numberOct, .numberFloat:
          it.fg(0x666666)
        case .operatorWord:
          it.fg(0xaa22ff).bold()
        case .nameBuiltin, .stringOther:
          it.fg(0x008000)
        case .nameFunction, .nameFunctionMagic:
          it.fg(0x0000ff)
        case .nameClass, .nameNamespace:
          it.fg(0x0000ff).bold()
        case .nameException:
          it.fg(0xcb3f38)
        case .nameVariable, .stringSymbol:
          it.fg(0x19177c)
        case .nameConstant:
          it.fg(0x880000)
        case .nameLabel:
          it.fg(0x767600)
        case .nameEntity:
          it.fg(0x717171).bold()
        case .nameAttribute:
          it.fg(0x687822)
        case .nameDecorator:
          it.fg(0xaa22ff)
        case .string:
          it.fg(0xba2121)
        case .stringDoc:
          it.fg(0xba2121).italic()
        case .genericEmph:
          it.italic()
        case .stringInterpol:
          it.fg(0xa45a77).bold()
        case .stringEscape:
          it.fg(0xaa5d1f).bold()
        case .stringRegex:
          it.fg(0xa45a77)
        case .genericHeading, .genericPrompt:
          it.fg(0x000080).bold()
        case .genericSubheading:
          it.fg(0x800080).bold()
        case .genericDeleted:
          it.fg(0xa00000)
        case .genericError:
          it.fg(0xe40000)
        case .genericStrong:
          it.bold()
        case .genericOutput:
          it.fg(0x717171)
        case .genericTraceback:
          it.fg(0x0044dd)
        case .error:
          it.border(0xff0000)
        default:
          it.fg(0x000000)
      }
    }.build()
  }
}
