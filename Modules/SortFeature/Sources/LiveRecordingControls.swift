import Foundation
import AVKit
import SwiftUI

@MainActor
enum LiveRecordingBackend {
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
  let model: LiveRecordingModel
  @State private var isPreviewPresented = false

  var body: some View {
    HStack(spacing: 10) {
      switch model.phase {
      case .idle, .failed, .ready:
        Button {
          Task { await model.start() }
        } label: {
          Label(String(localized: "Record Video", bundle: .module), systemImage: "record.circle")
        }
        .accessibilityIdentifier("liveRecordingStartButton")
      case .choosing:
        ProgressView(model.isUsingFallback
          ? String(localized: "Starting app recording…", bundle: .module)
          : String(localized: "Starting window recording…", bundle: .module))
          .accessibilityIdentifier("liveRecordingChoosingStatus")
        Button(String(localized: "Cancel", bundle: .module)) { Task { await model.cancel() } }
          .accessibilityIdentifier("liveRecordingCancelButton")
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 18.2, *), !model.isUsingFallback {
          Button(String(localized: "Record App Instead", bundle: .module)) {
            Task { await model.startUsing(ReplayKitLiveRecordingCapture()) }
          }
          .accessibilityIdentifier("liveRecordingFallbackButton")
        }
        #endif
      case .recording:
        Label(String(localized: "Recording", bundle: .module), systemImage: "record.circle.fill")
          .foregroundStyle(.red)
          .accessibilityIdentifier("liveRecordingActiveStatus")
        Button(String(localized: "Stop Recording", bundle: .module)) { Task { await model.stop() } }
          .accessibilityIdentifier("liveRecordingStopButton")
      case .saving:
        ProgressView(String(localized: "Saving video…", bundle: .module))
          .accessibilityIdentifier("liveRecordingSavingStatus")
      }

      if case .ready(let url) = model.phase {
        Button(String(localized: "Preview Video", bundle: .module)) { isPreviewPresented = true }
          .accessibilityIdentifier("liveRecordingPreviewButton")
        ShareLink(item: url) {
          Label(String(localized: "Share Video", bundle: .module), systemImage: "square.and.arrow.up")
        }
        .accessibilityIdentifier("liveRecordingShareButton")
      }
      if case .failed(let message) = model.phase {
        Text(message)
          .font(.caption)
          .foregroundStyle(.red)
          .accessibilityIdentifier("liveRecordingError")
      }
    }
    .frame(maxWidth: .infinity)
    .buttonStyle(.bordered)
    .font(.caption)
    .sheet(isPresented: $isPreviewPresented) {
      if case .ready(let url) = model.phase {
        NavigationStack {
          VideoPlayer(player: AVPlayer(url: url))
            .frame(minWidth: 320, minHeight: 240)
            .navigationTitle(String(localized: "Video Preview", bundle: .module))
            .toolbar {
              ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Done", bundle: .module)) { isPreviewPresented = false }
              }
            }
        }
      }
    }
  }
}
