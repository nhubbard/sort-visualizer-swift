import SwiftUI

/// Ported from `Legacy/Shared/Views/Main/MathView.swift` — a labeled equation row.
public struct MathView: View {
    private let text: String
    private let equation: String

    public init(text: String, equation: String) {
        self.text = text
        self.equation = equation
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text("\(text): ")
                .font(.system(size: 16, weight: .bold, design: .default))
                .multilineTextAlignment(.center)
            SwiftMathView(equation: equation, textAlignment: .right)
        }
    }
}
