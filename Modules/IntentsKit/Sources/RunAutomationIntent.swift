import AlgorithmKit
import AppIntents
import SortFeature

/// Opens Sort Symphony, selects `algorithm`, and awaits an entire `Automation` sweep (today's
/// ⌘⇧A Size Sweep or ⌘⌥⇧A Max Size Only) — replacing the *reachability* of those keyboard
/// shortcuts and the Automator menu without touching `SortSession.runAutomation(_:)` itself, which
/// both this intent and the in-app UI still call.
public struct RunAutomationIntent: AppIntent {
    public static var title: LocalizedStringResource { "Run Automation" }
    public static var description: IntentDescription {
        IntentDescription(
            "Runs a Sort Symphony automation sweep (like Size Sweep or Max Size Only) for one algorithm and waits for it to finish.",
            categoryName: "Sort Symphony",
            searchKeywords: ["Size Sweep", "Max Size Only", "Automation"])
    }

    public static var openAppWhenRun: Bool { true }

    @Parameter(title: "Algorithm", description: "The algorithm to run the automation on.")
    public var algorithm: AlgorithmEntity
    @Parameter(title: "Automation", description: "Which registered automation sweep to run.")
    public var automation: AutomationEntity

    public static var parameterSummary: some ParameterSummary {
        Summary("Run \(\.$automation) for \(\.$algorithm)")
    }

    public init() {}

    public init(algorithm: AlgorithmEntity, automation: AutomationEntity) {
        self.algorithm = algorithm
        self.automation = automation
    }

    /// Leaves `algorithm` unresolved (Shortcuts prompts for it) — `SortSymphonyShortcuts` uses
    /// this to pre-fill only which automation a given `AppShortcut` runs.
    public init(automation: AutomationEntity) {
        self.automation = automation
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        guard let realAlgorithm = AlgorithmRegistry.shared.algorithm(id: algorithm.algorithmID) else {
            throw SortSymphonyIntentError.algorithmUnavailable
        }
        await SortCoordinator.shared.runAutomation(algorithm: realAlgorithm, automationID: automation.automationID)
        return .result()
    }
}
