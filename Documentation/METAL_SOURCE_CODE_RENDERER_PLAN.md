# Metal Source-Code Renderer — Adapted to Sort Symphony

## Context

The algorithm-detail code viewer (`AlgorithmDetailSection` → `AttributedCodeView`, both real files today) has a known, previously-diagnosed language-switch stutter. Last session root-caused it precisely: `CodeHighlighter.highlight` is already `async` and already chunks styling work across a `TaskGroup` past 500 runs — that part is fast. The actual cost is `Text(AttributedString)` doing synchronous CoreText/TextKit layout on the main thread every time the string changes, worsened by `.fixedSize(horizontal: true, vertical: true)` forcing full-document measurement. At the time, the only fix identified (rasterize to a static image) was explicitly traded off against losing native `.textSelection(.enabled)` and declined as "chasing diminishing returns."

The externally-sourced Metal design doc reopens this with a fuller architecture: a fixed-cell glyph-atlas renderer with viewport culling, avoiding whole-document text layout entirely. Its diagnosis matches what we already found independently, and this session's exploration confirms the scale is real: `grailsort/py.md` alone is 425 lines with ~4,172 `code: 'Token.X'` annotations (~10 runs/line); the corpus is 1,699 markdown files with ~994,400 token annotations total. A single algorithm's source, once merged-adjacent, is still hundreds of styled spans — enough for CoreText layout to be the dominant cost the profiling already pointed at.

This plan translates the doc's concepts onto this codebase's real modules, types, and conventions, so language switching stops paying for full-document text layout. It reuses existing Metal infrastructure (`Modules/SortFeature/Sources/Metal*`) and the existing build-time packaging pipeline (`AlgorithmDetails.algz`) rather than inventing parallel systems.

**Platform note:** this app ships to iPadOS + Mac Catalyst only (no AppKit target) — every representable in the codebase is `UIViewRepresentable`, and Catalyst-specific behavior is handled inline with `#if targetEnvironment(macCatalyst)`, not a separate wrapper type. The plan below follows that convention; there is no NSViewRepresentable path to design.

---

## What already exists that this plan reuses directly

- **Metal plumbing** (`Modules/SortFeature/Sources/MetalRendererView.swift`, `MetalShapeRenderer.swift`, `MetalBarRenderer.swift`, `MetalSampleCount.swift`): MTKView wrapped in `UIViewRepresentable` + `Coordinator`, `isPaused=true`/`enableSetNeedsDisplay=true` for on-demand redraw, one persistent `MTLBuffer` (`storageModeShared`) mutated in place via `.contents().advanced(by:).storeBytes(of:)` for touched slots only, `MetalSampleCount.preferred(for:)` trying `[8,4,2,1]`, every renderer defaulting `sampleCount = 1` so offscreen tests stay unaffected. All of this transfers directly to a glyph-instance renderer — the "instance buffer of small structs, incrementally patched" idiom is exactly this doc's `GlyphInstance` model.
- **Test convention** (`Modules/SortFeature/Tests/MetalShapeRendererBufferConsistencyTests.swift`, `MetalPolygonRendererTests.swift`, `MetalShapeLayoutTests.swift`): offscreen `MTLTexture` + `getBytes` readback for GPU-output correctness, plus a separate no-GPU-device suite for pure layout math. New tests follow this exact split.
- **Build-time compaction already exists**: `App/Resources/AlgorithmDetails/manage.py`'s `pack` command already produces `AlgorithmDetails.algz` — an `ALGZ` envelope wrapping a zstd frame wrapping an `ADTL` manifest (`AlgorithmDetailsManifest.swift`, `AlgorithmDetailsEnvelope.swift`, both in `Modules/SortFeature/Sources/`), loaded at runtime by the `AlgorithmDetailStore` actor via `ZstdKit`. Today it only packages the raw annotated-markdown text — `AttributedString(localized:including:)` parsing and token-cascade styling still happen at runtime. This is the doc's "Compact Build-Time Resource Format" section, just not finished — extend it instead of building a new format.
- **Theme/token model** (`Modules/DesignSystemKit/Sources/CodeAttributes.swift`, `CodeTheme.swift`, `Themes/*.swift`): ~90 `CodeAttributes.Value` cases mirroring Pygments token names, per-theme `struct: CodeTheme` with a `[Value: TextFormat]` dictionary, cascade resolution via `token.parent` walking. No canonical integer style ID exists yet — this plan adds one without touching the 42 generated theme files or `Tools/GenerateThemes/generate_themes.py`.
- **Copy Code already works independently of the Text view**: the overlay button (`AlgorithmDetailSection.swift`) writes `UIPasteboard.general.string` from `plainSamples[selectedLanguage]`, a plain `String` extracted separately from the highlighted `AttributedString`. It has zero coupling to `.textSelection(.enabled)` — it survives the switch to Metal unchanged, and gets *simpler* once raw source bytes are available from the compact model directly (see Stage 1).

## What's genuinely new (no repo precedent)

Grepped for `CGContext|CoreText|CTFont|MTLTexture|makeTexture|CGImage` in production code — zero hits. Glyph rasterization into a texture atlas, fixed-cell layout math, and scroll-offset-driven viewport culling are new work; there's no existing scroll-view wrapper in the codebase either (plain SwiftUI `ScrollView` only, never represented). Budget for this honestly — this is the bulk of the real engineering effort, matching the doc's own complexity table.

---

## Staged Plan

### Stage 0 — Canonical Style ID (low risk, no visible change)

Add `CaseIterable` to `CodeAttributes.Value` (or a fixed `allCases`-ordered array if that's not mechanical). A style ID is just that case's index. For each of the 42 `CodeTheme` structs, add one computed, cached property:

```swift
extension CodeTheme {
  var colorTable: [SIMD4<Float>] {
    CodeAttributes.Value.allCases.map { getFormat(token: $0).foreground.simd4 }
  }
}
```

This reuses the existing `getFormat` cascade — no changes to `Tools/GenerateThemes/generate_themes.py` or the generated theme files. Ship this alone first; it's inert until something reads `colorTable`.

### Stage 1 — Extend the build-time pack step (optional but recommended before Metal)

Extend `manage.py pack` to also emit, per (algorithm, language) pair:

- the de-annotated UTF-8 source bytes (stripping the `^[text](code: '...')` wrapper — trivial regex, the annotation syntax is fixed and machine-generated);
- a line table (byte offset + length per line);
- a merged run table (adjacent same-style annotations collapsed into one run — the doc's "merge adjacent runs" step, done once at build time instead of every highlight call) with each run's style ID (Stage 0's ordering).

Add this as new content alongside the existing manifest entries in `AlgorithmDetailsManifest.swift`/`AlgorithmDetailsEnvelope.swift` — same envelope, same zstd frame, same `AlgorithmDetailStore` load path, just a couple more tables. This does **not** by itself fix the reported stutter (that's CoreText layout inside `Text`, not parsing) — but it removes runtime Markdown/AttributedString-run construction, shrinks the run count via merging, and gives the Metal renderer in Stage 3 a ready-made data model to consume. It also makes Copy Code simpler: the plain source bytes are already sitting in the container, no need to derive them from a styled `AttributedString` at runtime.

Keep the existing runtime `CodeHighlighter` path working unchanged during this stage — it's additive, not a replacement yet.

### Stage 2 — Glyph atlas + fixed-cell Metal prototype (new files, isolated, no UI wiring yet)

New files in `Modules/SortFeature/Sources/` (matching the existing Metal-lives-beside-its-feature convention — not a new module, and not registered in `MetalRendererFactory`, since that factory is specifically for the `VisualizerID` sort-visualizer switch, a different feature):

- `GlyphAtlas.swift` — rasterizes printable ASCII via Core Graphics/Core Text (`UIFont.monospacedSystemFont`, matching `TextFormat.swift`'s current hardcoded size-12 monospaced assumption) into a `CGContext` bitmap, uploads via `MTLTexture.replace(region:...)`. Preload ASCII at startup; no dynamic atlas growth yet.
- `GlyphRenderer.swift` + `GlyphRenderer.metal` — instanced quad renderer following `MetalShapeRenderer`'s exact buffer idiom: one persistent `GlyphInstance` buffer (position, size, uv, styleID), `storageModeShared`, incremental `storeBytes` writes. Fragment shader samples the grayscale mask and multiplies by `colors[styleID]` (Stage 0's table) — this part is genuinely simple, as the doc notes.
- `GlyphLayoutTests.swift` (pure fixed-cell column/row math, no GPU device — same shape as `MetalShapeLayoutTests.swift`) and `GlyphRendererBufferConsistencyTests.swift` (offscreen texture + `getBytes`, same shape as `MetalPolygonRendererTests.swift`).

Scope deliberately narrow: one document, one theme, ASCII only, ≤1 sample size class, vertical scroll only, no selection, no accessibility, no dynamic atlas insertion, `sampleCount` defaulted to `1` for tests exactly like every existing renderer. Validate against the compact model from Stage 1.

**Checkpoint before continuing:** measure the actual before/after language-switch latency here (simple timestamps around the highlight/present calls, or `os_signpost` if you want it in Instruments) and confirm the win is real before investing in Stages 3–5. This is the same gate the earlier "chasing diminishing returns" call was made at — worth re-checking it explicitly now that the approach has changed.

### Stage 3 — Wire into the feature

- New `SourceCodeMetalView.swift`: `UIViewRepresentable` wrapping an `MTKView`, `Coordinator` pattern identical to `MetalRendererView`'s (owns the atlas + renderer + current `HighlightedSource`, wires a `switchDocument`/`switchTheme` entry point the way `MetalRendererView.Coordinator.switchVisualizerIfNeeded` already does for mid-sort visualizer switches).
- Scrolling: no existing wrapper to reuse, so wrap the `MTKView` in a `UIScrollView`-backed representable directly (standard `UIScrollView` + `contentSize = lines.count * lineHeight × maxColumns * cellWidth`), reporting scroll offset to the renderer for viewport culling. This is ordinary UIKit, not a novel risk.
- Theme switching: swap the small `colors` buffer (Stage 0's `colorTable`) only — no document rebuild, matching the doc's design.
- Background token colors: second small instance buffer of rectangles, drawn before glyphs, per the doc's three-pass structure.
- Swap `AlgorithmDetailSection` to use `SourceCodeMetalView` behind a simple `SettingsKit`-style boolean flag during rollout (matches the project's existing pattern of feature flags living in `AppSettings`), so the old `AttributedCodeView` path stays available as a fallback until this is validated on-device.
- Copy Code: point it at Stage 1's raw source bytes directly instead of deriving plain text from a styled `AttributedString`.

### Stage 4 — Unicode fallback (likely low priority)

Check first whether any real sample actually needs it — these are machine-generated language snippets (Python/JS/Go/Java/C/C++/C#/Ruby/Kotlin/Swift), almost certainly ASCII plus the occasional comment. If a scan of the corpus turns up non-ASCII, add the doc's hybrid: fixed-cell for ASCII lines, a Core Text shaping fallback for lines that need it, cached behind the same line-rendering interface. If the corpus is clean ASCII, skip this stage.

### Stage 5 — Accessibility, selection (defer, revisit only if requested)

Start with one accessibility element for the whole visible document (`accessibilityLabel` from the plain source text already available from Stage 1) — cheap and better than nothing. Per-line elements are a real upgrade but not required to ship. Native text selection is the one capability this trades away; Copy Code already covers the primary use case (grabbing the whole sample), so treat drag-to-select as optional future work, not a blocker — consistent with the trade-off already accepted once to get here.

---

## Verification

- Stage 0/1: unit tests around the new pack-step output (byte ranges round-trip, run-merging produces expected collapsed runs, style IDs stable across themes) — extend existing `AlgorithmDetailStore`/manifest test coverage.
- Stage 2: `GlyphLayoutTests.swift` (deterministic column/row math) and `GlyphRendererBufferConsistencyTests.swift` (offscreen texture readback) in `Modules/SortFeature/Tests/`, following the exact existing pattern.
- Stage 3: this sandbox can't drive the live app (no screenshot/AppleScript automation available) — the actual "does language switching feel instant now" check has to happen on-device with the user. Ask for a manual before/after comparison rather than claiming success from tests alone.
- Throughout: run the module's existing test suite (`swift test` / Tuist test target for `SortFeature`) after each stage before moving to the next.
