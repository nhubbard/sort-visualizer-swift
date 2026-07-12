import SwiftUI

public protocol CodeTheme: Sendable {
    func getBgColor() -> Color
    func getFormat(token: CodeAttributes.Value) -> TextFormat
}
