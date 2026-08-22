import AppIntents

/// Marks this module as one App Intents' cross-module discovery should include — every
/// `AppIntent`/`AppEntity`/`AppShortcutsProvider` in this file's siblings lives here, in
/// `IntentsKit`, not in the app target itself. The app target's own conformance (see
/// `SortSymphonyAppIntentsPackage` in `App/Sources`) lists this type in its `includedPackages` —
/// both sides are required for the Shortcuts app to actually discover intents declared in a
/// framework rather than the main app module.
public struct IntentsKitPackage: AppIntentsPackage {
  public init() {}
}
