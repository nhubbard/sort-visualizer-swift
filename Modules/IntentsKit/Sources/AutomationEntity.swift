import AppIntents
import SortFeature

/// Same shape as `AlgorithmEntity`/`VisualizerEntity`/`ShuffleEntity` — wraps `SortFeature`'s
/// `Automation` (today's ⌘⇧A Size Sweep / ⌘⌥⇧A Max Size Only), resolved back through
/// `AutomationRegistry` by `id`. `RunAutomationIntent` pairs one of these with an `AlgorithmEntity`
/// to reproduce exactly what the keyboard shortcuts and Automator menu already trigger in-app.
public struct AutomationEntity: AppEntity {
    public let id: String
    public let displayName: String
    public let iconName: String

    public init(automation: Automation) {
        id = automation.id.rawValue
        displayName = automation.displayName
        iconName = automation.iconName
    }

    /// Plain memberwise form, for `SortSymphonyShortcuts`' pre-filled `AppShortcut`s — those are
    /// built from a static, fixed list of automations known at compile time, not looked up through
    /// `AutomationRegistry` (which may not be populated yet at the point the system evaluates
    /// `AppShortcutsProvider.appShortcuts`, well before `Sort2App.init()`'s composition root runs).
    public init(id: String, displayName: String, iconName: String) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
    }

    public var automationID: AutomationID { AutomationID(rawValue: id) }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation { "Automation" }
    public static let defaultQuery = AutomationEntityQuery()

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)", image: .init(systemName: iconName))
    }
}

public struct AutomationEntityQuery: EntityQuery, EnumerableEntityQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [String]) async -> [AutomationEntity] {
        identifiers.compactMap { rawID in
            AutomationRegistry.shared.automation(id: AutomationID(rawValue: rawID)).map(AutomationEntity.init)
        }
    }

    @MainActor
    public func suggestedEntities() async -> [AutomationEntity] {
        await allEntities()
    }

    @MainActor
    public func allEntities() async -> [AutomationEntity] {
        AutomationRegistry.shared.automations.map(AutomationEntity.init)
    }
}
