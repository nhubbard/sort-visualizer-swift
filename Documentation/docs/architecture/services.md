# Services

This layer consists of `PersistenceKit`, `SettingsKit`, `DesignSystemKit`, and `MathRenderingKit`.
These modules implement cross-cutting concerns that no single feature screen should own.

## `SettingsKit`: one `@Observable` singleton for user preferences

`AppSettings` (`@Observable @MainActor`, `AppSettings.shared`) backs every user-adjustable setting:
selected visualizer, playback speed, fixed-duration-pacing mode and its target duration, the
recording operation cap, the default shuffle, code theme, and others. Each property persists
itself in its own `didSet`, through a small wrapper over `UserDefaults`. Reading or writing a
setting is a plain property access, with no separate save step and no view-model layer.

`SettingsKit` depends on `VisualizationKit` and `AlgorithmKit` because settings reference
`VisualizerID`/`ShuffleID` values by ID and look them up through the same registries the rest of
the app uses. `defaultShuffleID`, for example, is a plain ID lookup against `ShuffleRegistry`, not
a hand-maintained enum.

`AppSettings` has no per-algorithm warning-toggle setting — no `warnBeforeBogoSort` boolean, which
an earlier design considered. That confirmation-dialog system was built partway through
development, then removed. `AlgorithmMetadata.sizeRange`'s unconditional clamp performs this
function for every algorithm uniformly, with no settings surface required. See
[Architecture overview](overview.md#platform-and-scope-decisions).

## `PersistenceKit`: CloudKit-synced run history

`AnalyticsService` (an actor, `AnalyticsService.shared`) is the only type that writes a completed
run's stats to disk. It is called only after `SortSession`'s phase transitions to `.complete`,
never from inside recording or replay. The engine layer has no knowledge that analytics exist.

Storage uses plain SwiftData, synced through `ModelConfiguration(cloudKitDatabase: .automatic)`.
This is not a hand-rolled CloudKit encoder and not `NSPersistentCloudKitContainer`. Two model
types:

- **`BigORecord`**: one row per completed run. It stores the same ArrayV-style operation counters
  `TapeHeader` tracks (compares, swaps, main and aux writes, reversals), plus `recordingDuration`
  (algorithmic time) and `playbackDuration`/`playbackSpeed` (wall-clock time spent watching the
  replay, and the pacing target used). These two duration values are kept separate because "the
  algorithm is fast but watching it is slow" is a real, measurable gap. `BigORecord` feeds the
  Big-O correlation chart (see [Features & app target](features.md)) across every device signed
  into the same iCloud account. It does not support comparing device speed across users, because a
  pacing target is a user-chosen setting, not a hardware measurement.
- **`RecordingCapExceededRecord`**: a write-only diagnostic row, inserted whenever an
  automation/sweep run hits `RecordingEngine`'s operation cap before finishing. No code reads this
  back. It exists so a developer can review, across devices, whether an algorithm's `sizeRange`
  needs narrowing.

Both model types give every property a concrete default value, even though the code that
constructs them always supplies real ones. A CloudKit-backed SwiftData model with a non-optional,
no-default attribute fails to sync at runtime, not at compile time. The defaults satisfy this
requirement.

`BigOCorrelation.swift` connects a `BigORecord` to a plotted chart point. It resolves an
algorithm's declared `timeComplexity` string (for example, `"O(n log n)"`) to a numeric value at a
given `n`. Some declared complexities reference a variable other than `n`:

- Radix sort's digit and bucket counts are fixed constants in this implementation.
- Counting, pigeonhole, and gravity sort's value range is approximately `n`, because every
  built-in shuffle keeps values within that range.
- Bingo sort's unique-value count is the exception. Two shuffles can produce duplicate values, so
  this case uses the algorithm's own observed `uniqueValueCount`/`arraySize` ratio instead of
  assuming it equals `n`.

## `DesignSystemKit`: shared UI, and the syntax-highlighting theme system

`DesignSystemKit` provides shared visual components (`CustomIconLabel` for the sidebar,
`RandomizingHeader`, `Color+Hex`) and the syntax-highlighting pipeline behind the app's
per-algorithm code samples.

- **`CodeAttributes`** defines a custom `AttributedString` key. It lets
  `AttributedString(markdown:including:)` parse the compact `^[text](code: 'Token.X')` markup the
  packed algorithm content uses (Pygments-style token names; see
  [Managing algorithm content](../guides/algorithm-content.md)) directly into styled runs.
- **`CodeTheme`** is a protocol, not a fixed lookup table. A theme declares only the tokens it
  styles differently from their parent. `getFormat(token:)` walks each token's `parent` chain — for
  example, `Token.Keyword.Type` falls back to `Token.Keyword`, then `Token` — until it finds an
  explicit entry. This is the same cascade Pygments uses to resolve a token's style from its
  nearest styled ancestor. Monokai, for example, declares around 25 entries instead of listing
  every leaf token that shares a color. All 56 themes under `Sources/Themes/` are generated by
  `Tools/GenerateThemes/generate_themes.py`, directly from Pygments' style data. No theme is
  hand-transcribed, so themes cannot drift from upstream the way the original hand-copied versions
  did. See [Dev tools](../reference/dev-tools.md#toolsgeneratethemes).
- **`CodeHighlighter`** performs the parse-and-format work once per content and theme change, off
  the main actor, rather than inside a view's `body`. An earlier version re-parsed and
  re-highlighted from scratch on every SwiftUI body evaluation of the algorithm detail screen. This
  caused a reported freeze whenever the language switched.

`DesignSystemKit` depends on `SettingsKit` for the selected `CodeThemeID`.

## `MathRenderingKit`: math typesetting for complexity notation

`MathRenderingKit` wraps the third-party `SwiftMath` package. `ComplexityRow` derives directly
from `AlgorithmMetadata.timeComplexity`/`spaceComplexity`, since every algorithm carries this data
as part of its own metadata. An earlier `complexity.json`-per-bundle scheme covered only a minority
of algorithms; this replaced it.

`ComplexityRow` escapes the plain-ASCII complexity strings authored alongside each algorithm — for
example, `"O(n log n)"` or `"O(n * n!)"` — into LaTeX: `\log` becomes a proper operator, `*`
becomes `\times`. `SwiftMathView`, a `UIViewRepresentable`/`NSViewRepresentable` over `SwiftMath`'s
`MTMathUILabel`, renders this LaTeX as typeset math instead of plain monospaced text. `MathView`
combines a label and an equation into one row (for example, "Worst Case: O(n²)"), which the
algorithm detail screen displays.

`MathRenderingKit` depends on `AlgorithmKit`, for `AlgorithmMetadata`, and the external `SwiftMath`
package.
