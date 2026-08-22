import AppIntents
import SettingsKit
import SortFeature

/// Sets `AppSettings.defaultArraySize` — like `SetShuffleIntent`, this affects the *next* run
/// `ContentView` starts, not one already replaying: `SortSession.arraySize` is fixed by whichever
/// `start(size:)` call began the current run, always clamped into that algorithm's own
/// `sizeRange`. `RunSortIntent` exposes a per-run override for changing it and starting
/// immediately. Named "Default" (not just "Set Array Size") specifically so it doesn't read as
/// "changes whatever's currently running" — a real point of confusion in testing, since this is
/// the one setting intent with no live-nudge counterpart at all (unlike speed/sound below).
public struct SetArraySizeIntent: AppIntent {
  public static var title: LocalizedStringResource { "Set Default Array Size" }
  public static var description: IntentDescription {
    IntentDescription(
      "Changes the default array size Sort Symphony sorts — takes effect on the next run, not one already on screen.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Array Size", "Default Size"])
  }

  @Parameter(
    title: "Size",
    description:
      "The default array size for future runs, clamped to whichever algorithm's own range when a run starts."
  )
  public var size: Int

  public static var parameterSummary: some ParameterSummary {
    Summary("Set default array size to \(\.$size)")
  }

  public init() {}

  public init(size: Int) {
    self.size = size
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    AppSettings.shared.defaultArraySize = size
    return .result()
  }
}

/// The App Intents equivalent of the manual size stepper's ⌘S shortcut — only meaningful against
/// whatever sort is currently on screen. Throws (rather than silently no-op'ing) when nothing's
/// open: an earlier silent no-op here was genuinely indistinguishable from "this doesn't work at
/// all" in testing — a thrown, worded error at least tells Shortcuts (and the person running it)
/// *why* nothing happened.
public struct CycleArraySizeIntent: AppIntent {
  public static var title: LocalizedStringResource { "Cycle Array Size" }
  public static var description: IntentDescription {
    IntentDescription(
      "Advances the array size of whichever sort is currently open in Sort Symphony.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Next Size", "Increase Size", "Bigger Array"])
  }

  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    guard let session = SortCoordinator.shared.activeSortSession else {
      throw SortSymphonyIntentError.noActiveSession
    }
    await session.cycleArraySize()
    return .result()
  }
}
