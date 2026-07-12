import SwiftUI

/// Ported from `Legacy/Shared/Views/Utilities/CustomIconLabel.swift`, but SF Symbol-based
/// (`Image(systemName:)`) rather than `Image.ofAsset(_:)` against a custom asset catalog — v2
/// never ported Legacy's per-algorithm icon image assets, so every `AlgorithmMetadata.iconName`
/// is now a real SF Symbol name instead of a custom asset name.
public struct CustomIconLabel: View {
    private let text: String
    private let iconName: String

    public init(text: String, iconName: String) {
        self.text = text
        self.iconName = iconName
    }

    public var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: iconName)
        }
    }
}
