import AVKit
import SwiftUI

@MainActor
private enum LiveRecordingBackend {
  static func make() -> any LiveRecordingCapturing {
    #if targetEnvironment(macCatalyst)
    if #available(macCatalyst 18.2, *) { return ScreenCaptureKitLiveRecordingCapture() }
    return ReplayKitLiveRecordingCapture()
    #else
    return ReplayKitLiveRecordingCapture()
    #endif
  }
}

@MainActor
struct LiveRecordingControls: View {
  @State private var model = LiveRecordingModel(capture: LiveRecordingBackend.make())
  @State private var isPreviewPresented = false

  var body: some View {
    HStack(spacing: 10) {
      switch model.phase {
      case .idle, .failed, .ready:
        Button {
          Task { await model.start() }
        } label: {
          Label("Record Video", systemImage: "record.circle")
        }
        .accessibilityIdentifier("liveRecordingStartButton")
      case .choosing:
        ProgressView(model.isUsingFallback ? "Starting app recording…" : "Choose a window to record…")
          .accessibilityIdentifier("liveRecordingChoosingStatus")
        Button("Cancel") { Task { await model.cancel() } }
          .accessibilityIdentifier("liveRecordingCancelButton")
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 18.2, *), !model.isUsingFallback {
          Button("Record App Instead") {
            Task { await model.startUsing(ReplayKitLiveRecordingCapture()) }
          }
          .accessibilityIdentifier("liveRecordingFallbackButton")
        }
        #endif
      case .recording:
        Label("Recording", systemImage: "record.circle.fill")
          .foregroundStyle(.red)
          .accessibilityIdentifier("liveRecordingActiveStatus")
        Button("Stop Recording") { Task { await model.stop() } }
          .accessibilityIdentifier("liveRecordingStopButton")
      case .saving:
        ProgressView("Saving video…")
          .accessibilityIdentifier("liveRecordingSavingStatus")
      }

      if case .ready(let url) = model.phase {
        Button("Preview Video") { isPreviewPresented = true }
          .accessibilityIdentifier("liveRecordingPreviewButton")
        ShareLink(item: url) {
          Label("Share Video", systemImage: "square.and.arrow.up")
        }
        .accessibilityIdentifier("liveRecordingShareButton")
      }
      if case .failed(let message) = model.phase {
        Text(message)
          .font(.caption)
          .foregroundStyle(.red)
          .accessibilityIdentifier("liveRecordingError")
      }
      Spacer(minLength: 0)
    }
    .buttonStyle(.bordered)
    .font(.caption)
    .padding(.horizontal)
    .sheet(isPresented: $isPreviewPresented) {
      if case .ready(let url) = model.phase {
        NavigationStack {
          VideoPlayer(player: AVPlayer(url: url))
            .frame(minWidth: 320, minHeight: 240)
            .navigationTitle("Video Preview")
            .toolbar {
              ToolbarItem(placement: .confirmationAction) {
                Button("Done") { isPreviewPresented = false }
              }
            }
        }
      }
    }
    .onDisappear {
      Task { await model.cancel() }
    }
  }
}
