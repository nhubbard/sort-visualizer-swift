import AppIntents
import IntentsKit

/// Declares that this app includes App Intents from `IntentsKit` — required alongside
/// `IntentsKitPackage`'s own `AppIntentsPackage` conformance for the Shortcuts app to discover
/// intents/entities/`AppShortcutsProvider`s declared in a framework rather than this app target
/// itself (see `IntentsKitPackage`'s doc comment for why both sides are needed).
struct SortSymphonyAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [IntentsKitPackage.self]
    }
}
