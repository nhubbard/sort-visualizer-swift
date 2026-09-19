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
- In `record(into:)`, route real comparisons through `RecordingEngine.compare`, `compareValue`, or `compareValues`; record meaningful auxiliary reads/writes through engine primitives. Repeated raw `engine.values` reads used for decisions hide work from operation counts and growth calibration.
- Fuzz ports on random, duplicate-heavy, sorted, and reversed input. Check stability empirically. Source algorithms and their metadata have had real correctness and complexity errors.
- In unattended automation, skip failures and durably log them without blocking UI; in manual runs, surface errors immediately. Reuse the existing automation state.
- Treat unexplained working-tree changes as possible user edits. Inspect before modifying or reverting; never discard them on an assumption.
- Run SwiftFormat serially if needed; prior parallel formatting corrupted source files.
- Tuist's manifest cache can miss dynamically discovered source files. Regenerate the project after adding files; clean manifests if discovery remains stale.

Claude's longer historical notes are at `~/.claude/projects/-Users-nhubbard-XcodeProjects-sort-visualizer-swift-xc16/memory/MEMORY.md`. They are useful background, but verify old paths, counts, and claims against current source and docs before relying on them.
