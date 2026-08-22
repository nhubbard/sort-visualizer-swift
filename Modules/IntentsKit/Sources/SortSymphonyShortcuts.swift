import AppIntents

/// The "ship pre-built Shortcuts with the app" half of the ask — these appear automatically in
/// the Shortcuts app, Spotlight, and Siri as soon as Sort Symphony is installed, with no import
/// step. `sizeSweep`/`maxSizeOnly` reproduce exactly what ⌘⇧A/⌘⌥⇧A and the Automator menu already
/// trigger in-app, prompting only for which algorithm to run.
public struct SortSymphonyShortcuts: AppShortcutsProvider {
  // `appShortcuts` is `@AppShortcutsBuilder`-backed (a result builder, like `@ViewBuilder`) —
  // each `AppShortcut(...)` below has to be its own bare statement, not wrapped in an array
  // literal, and has to be a literal initialization call rather than a variable that was
  // assigned to beforehand: App Intents' compile-time metadata extraction statically parses this
  // property's source text to know which parameters (e.g. `automation:` below) are pre-filled.
  public static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RunAutomationIntent(
        automation: AutomationEntity(
          id: "sizeSweep", displayName: "Size Sweep", iconName: "arrow.up.right")),
      phrases: [
        "Run a \(.applicationName) size sweep for \(\.$algorithm)",
        "Run \(.applicationName) size sweep"
      ],
      shortTitle: "Size Sweep",
      systemImageName: "arrow.up.right"
    )
    AppShortcut(
      intent: RunAutomationIntent(
        automation: AutomationEntity(
          id: "maxSizeOnly", displayName: "Max Size Only", iconName: "arrow.up.to.line")),
      phrases: [
        "Run a \(.applicationName) max size demo for \(\.$algorithm)",
        "Run \(.applicationName) max size demo"
      ],
      shortTitle: "Max Size Only",
      systemImageName: "arrow.up.to.line"
    )
    AppShortcut(
      intent: RunSortIntent(),
      phrases: [
        "Run \(\.$algorithm) in \(.applicationName)",
        "Run a sort in \(.applicationName)"
      ],
      shortTitle: "Run Sort",
      systemImageName: "play.fill"
    )
    AppShortcut(
      intent: RunShowcaseIntent(),
      phrases: [
        "Run a \(.applicationName) showcase",
        "Show me a \(.applicationName) showcase"
      ],
      shortTitle: "Showcase",
      systemImageName: "sparkles.tv.fill"
    )
    AppShortcut(
      intent: RunFullSizeSweepIntent(),
      phrases: [
        "Run a full \(.applicationName) size sweep",
        "Run a \(.applicationName) showcase sweep"
      ],
      shortTitle: "Full Size Sweep",
      systemImageName: "square.grid.3x3.fill"
    )
    AppShortcut(
      intent: RunVisualizerShowcaseIntent(),
      phrases: [
        "Run a \(.applicationName) visualizer showcase for \(\.$algorithm)",
        "Run a \(.applicationName) visualizer showcase"
      ],
      shortTitle: "Visualizer Showcase",
      systemImageName: "paintpalette.fill"
    )
  }
}
