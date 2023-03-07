//
//  MonokaiTheme.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/30/22.
//

import Foundation
import SwiftUI

// Yet another unreferenced file found by SwiftLint. Where are these located at!?!

let codeBgColor = Color(fromHex: "#272822")!
let codeHlColor = Color(fromHex: "#49483E")!

private let text = Color(fromHex: "#F8F8F2")!
private let baseColor = text
private let error = Color(fromHex: "#960050")!
private let comment = Color(fromHex: "#75715E")!
private let keyword = Color(fromHex: "#66D9EF")!
private let `operator` = Color(fromHex: "#F92672")!
private let punctuation = Color(fromHex: "#F8F8F2")!
private let name = Color(fromHex: "#A6E22E")!
private let number = Color(fromHex: "#AE81FF")!
private let string = Color(fromHex: "#E6DB74")!

let colorMap: [Token.TokenType: Color] = [
  .text: text,
  .whitespace: baseColor,
  .error: error,
  .other: baseColor,
  .comment: comment,
  .commentMultiline: comment,
  .commentPreproc: comment,
  .commentSingle: comment,
  .commentSpecial: comment,
  .commentHashbang: comment,
  .commentPreprocFile: comment,
  .keyword: keyword,
  .keywordConstant: keyword,
  .keywordDeclaration: keyword,
  .keywordNamespace: keyword,
  .keywordPseudo: keyword,
  .keywordReserved: keyword,
  .keywordType: keyword,
  .operator: `operator`,
  .operatorWord: `operator`,
  .punctuation: punctuation,
  .name: punctuation,
  .nameAttribute: name,
  .nameBuiltin: baseColor,
  .nameBuiltinPseudo: baseColor,
  .nameClass: name,
  .nameConstant: keyword,
  .nameDecorator: name,
  .nameEntity: baseColor,
  .nameException: name,
  .nameFunction: name,
  .nameProperty: baseColor,
  .nameLabel: baseColor,
  .nameNamespace: baseColor,
  .nameOther: baseColor,
  .nameTag: `operator`,
  .nameVariable: baseColor,
  .nameVariableClass: baseColor,
  .nameVariableGlobal: baseColor,
  .nameVariableInstance: baseColor,
  .number: number,
  .numberFloat: number,
  .numberHex: number,
  .numberInteger: number,
  .numberIntegerLong: number,
  .numberOct: number,
  .literal: number,
  .literalDate: string,
  .string: string,
  .stringBacktick: string,
  .stringChar: string,
  .stringDoc: string,
  .stringDouble: string,
  .stringEscape: number,
  .stringHeredoc: string,
  .stringInterpol: string,
  .stringOther: string,
  .stringRegex: string,
  .stringSingle: string,
  .stringSymbol: string,
  .generic: baseColor,
  .genericDeleted: `operator`,
  .genericEmph: baseColor,
  .genericError: baseColor,
  .genericHeading: baseColor,
  .genericInserted: name,
  .genericOutput: baseColor,
  .genericPrompt: baseColor,
  .genericStrong: baseColor,
  .genericSubheading: comment,
  .genericTraceback: baseColor
]
