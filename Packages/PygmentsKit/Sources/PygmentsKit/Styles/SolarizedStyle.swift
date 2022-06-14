//
//  SolarizedLightStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import SwiftUI
import Then

fileprivate enum LightColors: UInt {
  case base3 = 0x002b36
  case base2 = 0x073642
  case base1 = 0x586e75
  case base0 = 0x657b83
  case base00 = 0x839496
  case base01 = 0x93a1a1
  case base02 = 0xeee8d5
  case base03 = 0xfdf6e3
  case yellow = 0xb58900
  case orange = 0xcb4b16
  case red = 0xdc322f
  case magenta = 0xd33682
  case violet = 0x6c71c4
  case blue = 0x268bd2
  case cyan = 0x2aa198
  case green = 0x859900
}

fileprivate enum DarkColors: UInt {
  case base03 = 0x002b36
  case base02 = 0x073642
  case base01 = 0x586e75
  case base00 = 0x657b83
  case base0 = 0x839496
  case base1 = 0x93a1a1
  case base2 = 0xeee8d5
  case base3 = 0xfdf6e3
  case yellow = 0xb58900
  case orange = 0xcb4b16
  case red = 0xdc322f
  case magenta = 0xd33682
  case violet = 0x6c71c4
  case blue = 0x268bd2
  case cyan = 0x2aa198
  case green = 0x859900
}

class SolarizedLightStyle: BaseStyle {
  /// The name of this style.
  var name: String = "solarizedLight"
  
  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: LightColors.base03.rawValue)
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .nameBuiltin, .nameBuiltinPseudo, .nameClass, .nameConstant, .nameDecorator, .nameEntity, .nameException,
             .nameFunction, .nameFunctionMagic, .nameLabel, .nameNamespace, .nameTag, .nameVariable,
             .nameVariableGlobal, .nameVariableMagic, .genericTraceback:
          it.fg(LightColors.blue.rawValue)
        case .keywordConstant, .keywordDeclaration, .string, .stringChar, .stringAffix, .stringOther, .stringDouble,
             .stringEscape, .stringSingle, .stringSymbol, .stringHeredoc, .stringBacktick, .stringInterpol,
             .stringDelimiter, .number, .numberInteger, .numberIntegerLong, .numberBin, .numberHex, .numberOct,
             .numberFloat:
          it.fg(LightColors.cyan.rawValue)
        case .token, .generic, .genericOutput:
          it.fg(LightColors.base0.rawValue)
        case .keyword, .operatorWord, .genericInserted:
          it.fg(LightColors.green.rawValue)
        case .commentHashbang, .commentMultiline, .operator, .stringDoc:
          it.fg(LightColors.base01.rawValue)
        case .keywordType:
          it.fg(LightColors.yellow.rawValue)
        case .keywordNamespace, .stringRegex:
          it.fg(LightColors.orange.rawValue)
        case .genericDeleted, .genericError:
          it.fg(LightColors.red.rawValue)
        case .error:
          it.bg(LightColors.red.rawValue)
        case .genericHeading, .genericStrong:
          it.bold()
        case .genericPrompt:
          it.fg(LightColors.blue.rawValue).bold()
        case .genericEmph:
          it.italic()
        case .comment:
          it.fg(LightColors.base01.rawValue).italic()
        case .commentPreprocFile:
          it.fg(LightColors.base01.rawValue)
        case .commentPreproc:
          it.fg(LightColors.magenta.rawValue)
        case .genericSubheading:
          it.fg(LightColors.base00.rawValue).underline()
        default:
          it.fg(LightColors.base00.rawValue)
      }
    }.build()
  }
}

class SolarizedDarkStyle: BaseStyle {
  /// The name of this style.
  var name: String = "solarizedDark"
  
  /// The background color used by this style. Defaults to `.white`.
  var backgroundColor: Color = Color(hex: DarkColors.base03.rawValue)
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat {
    TextFormat.getBuilder(bg: backgroundColor).then { it in
      switch tokenType {
        case .nameBuiltin, .nameBuiltinPseudo, .nameClass, .nameConstant, .nameDecorator, .nameEntity, .nameException,
             .nameFunction, .nameFunctionMagic, .nameLabel, .nameNamespace, .nameTag, .nameVariable,
             .nameVariableGlobal, .nameVariableMagic, .genericTraceback:
          it.fg(DarkColors.blue.rawValue)
        case .keywordConstant, .keywordDeclaration, .string, .stringChar, .stringAffix, .stringOther, .stringDouble,
             .stringEscape, .stringSingle, .stringSymbol, .stringHeredoc, .stringBacktick, .stringInterpol,
             .stringDelimiter, .number, .numberInteger, .numberIntegerLong, .numberBin, .numberHex, .numberOct,
             .numberFloat:
          it.fg(DarkColors.cyan.rawValue)
        case .token, .generic, .genericOutput:
          it.fg(DarkColors.base0.rawValue)
        case .keyword, .operatorWord, .genericInserted:
          it.fg(DarkColors.green.rawValue)
        case .commentHashbang, .commentMultiline, .operator, .stringDoc:
          it.fg(DarkColors.base01.rawValue)
        case .keywordType:
          it.fg(DarkColors.yellow.rawValue)
        case .keywordNamespace, .stringRegex:
          it.fg(DarkColors.orange.rawValue)
        case .genericDeleted, .genericError:
          it.fg(DarkColors.red.rawValue)
        case .error:
          it.bg(DarkColors.red.rawValue)
        case .genericHeading, .genericStrong:
          it.bold()
        case .genericPrompt:
          it.fg(DarkColors.blue.rawValue).bold()
        case .genericEmph:
          it.italic()
        case .comment:
          it.fg(DarkColors.base01.rawValue).italic()
        case .commentPreprocFile:
          it.fg(DarkColors.base01.rawValue)
        case .commentPreproc:
          it.fg(DarkColors.magenta.rawValue)
        case .genericSubheading:
          it.fg(DarkColors.base00.rawValue).underline()
        default:
          it.fg(DarkColors.base00.rawValue)
      }
    }.build()
  }
}
