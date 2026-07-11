import AlgorithmKit
import SwiftUI

public struct ScrollingSortView: View {
    let algorithm: any SortAlgorithm
    let arraySize: Int
    @State private var session: SortSession

    @MainActor
    public init(algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, arraySize: Int = 48) {
        self.algorithm = algorithm
        self.arraySize = arraySize
        // NOT audio: AudioService.shared here — this predates the ToneKit migration (see
        // Modules/ToneKit/NOTICE.md), when constructing a live AudioKit graph crashed in this
        // project's toolchain/simulator combination at native AudioComponent registration, a crash
        // Swift couldn't catch (a C++ assert -> SIGABRT). That specific crash risk no longer
        // exists — ToneKit is plain AVAudioEngine/AVAudioSourceNode — but wiring the real
        // AudioService.shared into the one screen every UI test exercises is still a real,
        // separate decision (every UI test would start exercising live audio) rather than
        // something to flip as a side effect of the AudioKit removal. AudioService.swift remains
        // fully implemented and unit-tested (its pure frequency(forValue:in:noteRange:) math);
        // SortSession's own default (NoOpAudioService()) keeps this screen silent until that
        // decision is made deliberately.
        _session = State(wrappedValue: SortSession(algorithm: algorithm, shuffle: shuffle))
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
            // Zero-size, fully transparent — this button exists only to give ⌘⇧A somewhere to
            // land, scoped to whichever algorithm screen is currently showing. A global `Commands`
            // scene would need `FocusedValue` plumbing to reach this specific session instead.
            Button("") { session.toggleAutomation() }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
    }
}
