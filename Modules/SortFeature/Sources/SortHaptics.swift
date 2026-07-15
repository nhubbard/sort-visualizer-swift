import UIKit

/// Three deliberately narrow haptic touchpoints — not sprinkled across every control. Shared
/// between `RunControlBar`'s buttons and `SortCommands`' scene-level menu actions (the `App`
/// target) so the feedback feels identical whether a control is tapped or its keyboard shortcut is
/// used, since both paths end up calling the exact same `SortSession`/`ReplayEngine` methods.
public enum SortHaptics {
    public static func playPauseToggled() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func reset() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    public static func speedClamped() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}
