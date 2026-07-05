import SwiftUI
import Then

// Colors based on CSS class names.
private let hl = Color(fromHex: "#F8F8F8")!
private let c = Color(fromHex: "#3D7B7B")!
private let err = Color(fromHex: "#FF0000")!
private let k = Color(fromHex: "#008000")!
private let o = Color(fromHex: "#666666")!
private let cp = Color(fromHex: "#9C6500")!
private let gd = Color(fromHex: "#A00000")!
private let gr = Color(fromHex: "#E40000")!
private let gh = Color(fromHex: "#000080")!
private let gi = Color(fromHex: "#008400")!
private let go = Color(fromHex: "#717171")!
private let gu = Color(fromHex: "#800080")!
private let gt = Color(fromHex: "#0044DD")!
private let kt = Color(fromHex: "#B00040")!
private let s = Color(fromHex: "#BA2121")!
private let na = Color(fromHex: "#687822")!
private let nc = Color(fromHex: "#0000FF")!
private let no = Color(fromHex: "#880000")!
private let nd = Color(fromHex: "#AA22FF")!
private let ne = Color(fromHex: "#CB3F38")!
private let nl = Color(fromHex: "#767600")!
private let nv = Color(fromHex: "#19177C")!
private let w = Color(fromHex: "#BBBBBB")!
private let se = Color(fromHex: "#AA5D1F")!
private let si = Color(fromHex: "#A45A77")!

public struct PygmentsTheme: CodeTheme {
    public init() {}
    public func getBgColor() -> Color { hl }
    public func getFormat(token: CodeAttributes.Value) -> TextFormat {
        TextFormat.getBuilder(bg: hl).then { it in
            switch token {
            case .comment:
                it.fg(c).italic()
            case .error:
                it.bg(err)
            case .commentHashbang, .commentMultiline, .commentPreprocFile, .commentSingle, .commentSpecial:
                it.fg(c).italic()
            case .commentPreproc:
                it.fg(cp)
            case .genericDeleted:
                it.fg(gd)
            case .genericEmph:
                it.italic()
            case .genericError:
                it.fg(gr)
            case .genericHeading, .genericPrompt:
                it.fg(gh).bold()
            case .genericInserted:
                it.fg(gi)
            case .genericOutput:
                it.fg(go)
            case .nameEntity:
                it.fg(go).bold()
            case .genericStrong:
                it.bold()
            case .genericSubheading:
                it.fg(gu).bold()
            case .genericTraceback:
                it.fg(gt)
            case .keyword, .keywordConstant, .keywordDeclaration, .keywordNamespace, .keywordReserved, .nameTag:
                it.fg(k).bold()
            case .keywordPseudo, .nameBuiltin, .stringOther, .nameBuiltinPseudo:
                it.fg(k)
            case .keywordType:
                it.fg(kt)
            case .operator, .number, .numberBin, .numberFloat, .numberHex, .numberInteger, .numberOct, .numberIntegerLong:
                it.fg(o)
            case .string, .stringAffix, .stringBacktick, .stringChar, .stringDelimiter, .stringDouble, .stringHeredoc,
                 .stringSingle:
                it.fg(s)
            case .nameAttribute:
                it.fg(na)
            case .nameFunction, .nameFunctionMagic:
                it.fg(nc)
            case .nameClass, .nameNamespace:
                it.fg(nc).bold()
            case .nameConstant:
                it.fg(no)
            case .nameDecorator:
                it.fg(nd)
            case .operatorWord:
                it.fg(nd).bold()
            case .nameException:
                it.fg(ne).bold()
            case .nameLabel:
                it.fg(nl)
            case .nameVariable, .nameVariableClass, .nameVariableGlobal, .nameVariableInstance, .nameVariableMagic,
                 .stringSymbol:
                it.fg(nv)
            case .whitespace:
                it.fg(w)
            case .stringDoc:
                it.fg(s).italic()
            case .stringEscape:
                it.fg(se).bold()
            case .stringRegex:
                it.fg(si)
            case .stringInterpol:
                it.fg(si).bold()
            default:
                it.fg(.black)
            }
        }.build()
    }
}
