import AlgorithmKit
import AudioEngineKit
import SettingsKit
import SwiftUI

public struct ScrollingSortView: View {
    let algorithm: any SortAlgorithm
    let arraySize: Int
    @State private var session: SortSession
    @Environment(AppSettings.self) private var settings

    @MainActor
    public init(algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, arraySize: Int = 48) {
        self.algorithm = algorithm
        self.arraySize = arraySize
        // AudioService.shared, for real: this used to default to NoOpAudioService() because
        // constructing a live AudioKit graph crashed in this project's toolchain/simulator
        // combination at native AudioComponent registration, a crash Swift couldn't catch (a C++
        // assert -> SIGABRT). That risk doesn't exist for ToneKit (plain AVAudioEngine/
        // AVAudioSourceNode — see Modules/ToneKit/NOTICE.md), and `AudioService.play()`'s `try?
        // start()` already fails silently rather than crashing if a given host has no usable
        // audio route (e.g. a sandboxed CI runner), so there's no reason left to keep this screen
        // silent. `AppSettings.soundEnabled` (Settings) still gates whether a sort plays anything
        // at all; this is just which backend answers when it does.
        _session = State(wrappedValue: SortSession(algorithm: algorithm, shuffle: shuffle, audio: AudioService.shared))
    }

    public var body: some View {
        // Matches Legacy/Shared/Views/Main/ScrollingSortView.swift's own GeometryReader approach:
        // the sort visualization fills the whole visible viewport on first appearance (not a
        // fixed/minimum height), with the detail section sitting below the fold — a deliberate
        // "the animation is the main event" layout, not a byproduct of ScrollView's own sizing.
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SortView(session: session)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    AlgorithmDetailSection(algorithm: algorithm)
                }
            }
        }
        .navigationTitle(algorithm.metadata.displayName)
        .task {
            // SortSession.start(size:) clamps into algorithm.metadata.sizeRange itself, so
            // every caller gets that enforcement, not just this one.
            await session.start(size: arraySize)
        }
        .background {
            // Zero-size, fully transparent — these buttons exist only to give ⌘⇧A/⌘⌥⇧A/⌘⇧V
            // somewhere to land, scoped to whichever algorithm screen is currently showing. A
            // global `Commands` scene would need `FocusedValue` plumbing to reach this specific
            // session instead.
            Button("") { session.toggleAutomation() }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            // Same bulk-data-generation loop, constrained to this algorithm's own maximum size —
            // for generating fresh recording/playback-duration samples at the size most likely to
            // show a visualization-time anomaly, without waiting through every smaller size first.
            Button("") { session.toggleMaxSizeAutomation() }
                .keyboardShortcut("a", modifiers: [.command, .option, .shift])
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            // On-demand visualizer cycling — unlike the two automations above, this isn't a loop:
            // one press advances `AppSettings.selectedVisualizerID` by exactly one step through
            // `VisualizerRegistry`'s stable order, ring-buffer-wrapping back to the first past the
            // last. Not gated on `session.isAutomating`/run completion — switching mid-run just
            // changes what's drawn going forward from the same `ReplayEngine` state, which is
            // already safe (every renderer reads `selectedVisualizerID` reactively).
            Button("") { settings.cycleVisualizer() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}
