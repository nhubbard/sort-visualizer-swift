import SwiftUI
import Then

private let comment = Color(fromHex: "#95a5a6")!
private let error = Color(fromHex: "#a61717")!
private let keyword = Color(fromHex: "#728e00")!
private let name = Color(fromHex: "#434f54")!
private let otherKeyword = Color(fromHex: "#00979d")!
private let number = Color(fromHex: "#8a7b52")!
private let string = Color(fromHex: "#7f8c8d")!
private let functionName = Color(fromHex: "#d35400")!

public struct ArduinoTheme: CodeTheme {
    public init() {}
    public func getBgColor() -> Color { .white }
    public func getFormat(token: CodeAttributes.Value) -> TextFormat {
        TextFormat.getBuilder(bg: .white).then { it in
            switch token {
            case .comment, .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
                it.fg(comment)
            case .error:
                it.fg(error)
            case .keyword, .operator, .commentPreproc, .keywordDeclaration, .keywordNamespace, .nameBuiltin, .nameOther,
                 .operatorWord, .nameBuiltinPseudo:
                it.fg(keyword)
            case .name, .nameAttribute, .nameClass, .nameConstant, .nameDecorator, .nameEntity, .nameException, .nameLabel,
                 .nameNamespace, .nameProperty, .nameTag, .nameVariable, .nameVariableClass, .nameVariableGlobal,
                 .nameVariableInstance, .nameVariableMagic:
                it.fg(name)
            case .keywordConstant, .keywordPseudo, .keywordReserved, .keywordType:
                it.fg(otherKeyword)
            case .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
                it.fg(number)
            case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDoc, .stringDouble,
                 .stringEscape, .stringHeredoc, .stringInterpol, .stringOther, .stringRegex, .stringSingle, .stringSymbol:
                it.fg(string)
            case .nameFunction, .nameFunctionMagic:
                it.fg(functionName)
            default:
                it.fg(.black)
            }
        }.build()
    }
}
