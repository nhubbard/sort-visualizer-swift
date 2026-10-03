# Project context for coding agents

This is **Sort Symphony**, a Swift/SwiftUI sorting visualizer for iOS, iPadOS, and Mac Catalyst. Tuist generates the workspace from `Project.swift` and `Tuist/`; the generated Xcode project is not the source of truth. Read `README.md` and `Documentation/docs/architecture/` for the current design.

## Architecture

- `Modules/SortEngineKit`: `RecordingEngine` records algorithm operations into a tape; `ReplayEngine` provides playback, stepping, and seeking.
- `Modules/AlgorithmKit` and `Modules/BuiltInAlgorithms`: algorithm protocols, metadata, registry, and native Swift sort/shuffle implementations.
- `Modules/VisualizationKit` and `Modules/BuiltInVisualizers`: visualizer interfaces and styles. The app uses Metal rendering; algorithm code is independent of the selected visualizer.
- `Modules/SortFeature`: sort UI, session coordination, and rendering host. Other feature and service modules cover settings, App Intents, audio, analytics, and persistence.
- `App/`: app and AUv3 targets. `Tools/`: calibration, content, complexity, and performance tooling.

## Working rules learned from prior development

- Build and test Swift with `tuist` or `xcodebuild`, not IntelliJ's Swift build/problem tools. See `README.md` and `Documentation/docs/guides/building.md`.
- For algorithm ports, use `Documentation/docs/guides/adding-an-algorithm.md` and `Documentation/docs/reference/port-status.md`. Some older Claude notes point to removed `Documentation/ALGORITHM_PORTING_PROCESS.md` and `Documentation/PORT_INVENTORY.md` paths.
- In `record(into:)`, route real comparisons through `RecordingEngine.compare`, `compareValue`, or `compareValues`; read live values through `readValue(at:)`, `readValues(in:)`, or `readAllValues()` so every read enters the tape. Record meaningful auxiliary reads/writes through engine primitives. Run `python3 Tools/EngineAccessAudit/audit.py` after editing algorithms.
- Fuzz ports on random, duplicate-heavy, sorted, and reversed input. Check stability empirically. Source algorithms and their metadata have had real correctness and complexity errors.
- In unattended automation, skip failures and durably log them without blocking UI; in manual runs, surface errors immediately. Reuse the existing automation state.
- Treat unexplained working-tree changes as possible user edits. Inspect before modifying or reverting; never discard them on an assumption.
- Run SwiftFormat serially if needed; prior parallel formatting corrupted source files.
- Tuist's manifest cache can miss dynamically discovered source files. Regenerate the project after adding files; clean manifests if discovery remains stale.
- Check the current Git branch before beginning repository changes. When an algorithm implementation and a corpus-wide content cleanup are both requested, keep them in separate commits and preserve the requested commit order.
- InstrumentsKit is intentionally disabled. Do not re-enable, register, link, or otherwise alter it unless the user explicitly requests that change.

## Algorithm description style

- Algorithm descriptions are embedded inside an already structured interface. Write them as paragraphs only. Do not add headings, lists, tables, block quotes, code blocks, horizontal rules, images, raw HTML, or display-math markup.
- The only permitted inline Markdown is bold, italics, and links to English Wikipedia. Do not add non-Wikipedia links. Keep emphasis markers and quotation marks balanced, and run a corpus-wide structural scan after mechanical edits.
- Follow Wikipedia's Manual of Style: open by identifying the exact algorithm or variant, use neutral and concise prose, expand abbreviations at first use, explain necessary jargon, and omit conversational framing, rhetorical questions, second-person language, contractions, promotional language, and redundant summaries.
- Avoid stock AI phrasing and peacock terms. In particular, do not use words such as “delve”, “landscape”, “groundbreaking”, “seamless”, “crucial”, “showcases”, or “highlights”. Avoid “not only … but also”, arbitrary groups of three, self-references to the codebase, and boilerplate such as “From Wikipedia, the free encyclopedia”.
- Avoid em dashes in descriptions. Prefer a period, semicolon, comma, or parentheses according to the sentence structure. Watch for comma splices after mechanical dash replacement.
- Use logical quotation punctuation: place a comma or period inside quotation marks only when it belongs to the quoted material.
- Present mathematical notation as prose typography rather than programming syntax. Use `×`, `÷`, and the true minus sign `−`; use superscripts such as `n²` where practical; and put spaces around binary operators. Do not write prose formulae with `*`, `/`, `^`, or a hyphen-minus used as subtraction.
- Audit the entire description corpus, including the scaffold template and descriptions that appear unchanged. Useful checks include unauthorized Markdown, non-Wikipedia links, unbalanced emphasis or quotes, contractions, prohibited wording, second person, rhetorical questions, programming-style operators, trailing whitespace, and `git diff --check`.
- After any description change, run `uv run manage.py pack` from `App/Resources/AlgorithmDetails`. A successful pack must verify the outer header, SHA-256 digest, zstd checksum, and manifest against the source before the regenerated `AlgorithmDetails.algz` is committed.

## Reference implementation preferences

- The ten-language samples in `App/Resources/AlgorithmDetails/` are teaching examples. Preserve
  each algorithm's defining logic and make the control flow easy to follow; exhaustive behavior
  on every possible input is not the goal. Prefer clear, multiline implementations over compressed
  one-liners or dense formatting.
- Use the files in `App/Resources/AlgorithmDetails/template/` as the structural baseline. Put
  shared template declarations and methods (including the public `sort` entry point) first,
  algorithm-specific helpers next, and the executable `main` or sample block last. Use forward
  declarations or thin wrappers where a language requires them, without obscuring the algorithm.
- Improve efficiency when the simpler implementation is also clearer, as with the C/C++
  `printList` loop. Do not replace an algorithm's characteristic steps merely to optimize a
  demonstration.
- After editing reference sources, use `App/Resources/AlgorithmDetails/manage.py` to run the
  relevant `test` checks, then `highlight` and `pack` so the shipped `AlgorithmDetails.algz`
  matches the source. Check the rendered code for readability when formatting changes are broad.
- Do not impose one 128-element input on every sample: calibrated slow algorithms need smaller
  examples, and a unique-value permutation does not cover duplicate paths. Add size-aware test
  cases when needed rather than making the displayed example unwieldy.
- For broad reference changes, group related source edits into focused commits and keep generated
  content separate. Temporary verification ledgers should not remain in the final PR tree; check
  the PR base and explain inherited branch history before publishing.

Claude's longer historical notes are at `~/.claude/projects/-Users-nhubbard-XcodeProjects-sort-visualizer-swift-xc16/memory/MEMORY.md`. They are useful background, but verify old paths, counts, and claims against current source and docs before relying on them.
