import AlgorithmKit
import SwiftUI

public struct AutomationID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The `⌘⇧A` bulk-data-generation loop: every size in `sizeRange`, stepped by `sizeStep`.
    public static let sizeSweep = AutomationID(rawValue: "sizeSweep")
    /// The `⌘⌥⇧A` loop: just `sizeRange.upperBound`, for samples at the size most likely to show
    /// visualization-time anomalies without waiting through every smaller size first.
    public static let maxSizeOnly = AutomationID(rawValue: "maxSizeOnly")
}

/// One entry per automation: the sizes/runs it drives through `SortSession.runAutomation(_:)`, and
/// the keyboard shortcut that triggers it, declared together so there's one source of truth
/// instead of a shortcut hardcoded separately from what it runs (see `ScrollingSortView`'s
/// invisible shortcut buttons and `RunControlBar`'s Automator menu, both of which read this).
public struct Automation: Sendable, Identifiable {
    public let id: AutomationID
    public let displayName: String
    public let iconName: String
    public let key: KeyEquivalent
    public let modifiers: EventModifiers
    public let runsPerSize: Int
    public let sizes: @Sendable (AlgorithmMetadata) -> [Int]

    public init(
        id: AutomationID,
        displayName: String,
        iconName: String,
        key: KeyEquivalent,
        modifiers: EventModifiers,
        runsPerSize: Int,
        sizes: @Sendable @escaping (AlgorithmMetadata) -> [Int]
    ) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
        self.key = key
        self.modifiers = modifiers
        self.runsPerSize = runsPerSize
        self.sizes = sizes
    }

    /// The modifier/key combo as the same Unicode glyphs used throughout this app's tooltips
    /// (`⌘`/`⌥`/`⇧`/`⌃`), for display in the Automator menu.
    public var shortcutDisplayString: String {
        var result = ""
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }
        result += String(key.character).uppercased()
        return result
    }
}

/// Same shape as `AlgorithmRegistry`/`VisualizerRegistry` (`AlgorithmKit`/`VisualizationKit`) — a
/// singleton with an externally-settable `builtIns` array, populated once at the app's composition
/// root (`Sort2App.init()`). Lives in `SortFeature`, not `AlgorithmKit`, because automations are
/// tied to `SortSession`, which lives here.
@MainActor
public final class AutomationRegistry {
    public static let shared = AutomationRegistry()

    public private(set) var automations: [Automation] = []
    public var builtIns: [Automation] = []

    public init() {}

    public func discover() {
        automations = builtIns
    }

    public func automation(id: AutomationID) -> Automation? {
        automations.first { $0.id == id }
    }
}
