import SortFeature
import SwiftUI

/// Entry point that replaces the old Benchmark button — runs `ShowcaseController` end to end,
/// rendering whichever session is currently active via `SortFeature`'s own `SortView`, exactly
/// like a normal algorithm screen, just advancing to the next algorithm automatically instead of
/// waiting for a person to navigate there.
public struct ShowcaseView: View {
    @State private var controller = ShowcaseController()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            progressBanner
            content
        }
        .navigationTitle("Showcase")
        .task {
            controller.start()
        }
        .onDisappear {
            controller.stop()
        }
    }

    private var progressBanner: some View {
        HStack(spacing: 8) {
            if controller.isRunning {
                ProgressView()
                    .controlSize(.small)
            }
            Text(progressText)
                .font(.caption)
                .accessibilityIdentifier("showcaseProgressLabel")
            Spacer()
            Button("Stop") { controller.stop() }
                .font(.caption)
                .disabled(!controller.isRunning)
                .accessibilityIdentifier("showcaseStopButton")
        }
        .padding(.horizontal)
    }

    private var progressText: String {
        let algorithms = controller.algorithms
        guard controller.isRunning, controller.currentIndex < algorithms.count else {
            return controller.isRunning ? "Starting…" : "Showcase finished"
        }
        let algorithm = algorithms[controller.currentIndex]
        return "Algorithm \(controller.currentIndex + 1)/\(algorithms.count): \(algorithm.metadata.displayName)"
    }

    @ViewBuilder
    private var content: some View {
        if let session = controller.currentSession {
            SortView(session: session)
                .id(ObjectIdentifier(session))
        } else {
            ContentUnavailableView(
                controller.isRunning ? "Starting Showcase…" : "Showcase Finished",
                systemImage: "sparkles.tv"
            )
        }
    }
}
