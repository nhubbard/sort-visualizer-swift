import Foundation
@preconcurrency import ReplayKit

/// ReplayKit writes the app's video and audio directly to a file on iPadOS 18–26 and serves as
/// the fallback on Mac Catalyst 18.0–18.1, before ScreenCaptureKit recording is available there.
/// ScreenCaptureKit's equivalent iPad API starts at iPadOS 27, after this app's deployment target.
@MainActor
final class ReplayKitLiveRecordingCapture: NSObject, LiveRecordingCapturing, RPScreenRecorderDelegate {
  var onInterruption: ((Error) -> Void)?
  private let recorder = RPScreenRecorder.shared()
  private var startContinuation: CheckedContinuation<Void, Error>?
  private var startTimeout: Task<Void, Never>?
  private var isStopping = false

  func start() async throws {
    guard recorder.isAvailable, !recorder.isRecording else { throw LiveRecordingError.unavailable }
    recorder.delegate = self
    recorder.isMicrophoneEnabled = false
    try await withCheckedThrowingContinuation { continuation in
      startContinuation = continuation
      startTimeout = Task { @MainActor [weak self] in
        do { try await Task.sleep(for: .seconds(20)) }
        catch { return }
        guard let self, let continuation = self.startContinuation else { return }
        self.startContinuation = nil
        continuation.resume(throwing: LiveRecordingError.startTimedOut)
        await self.cancel()
      }
      recorder.startRecording { [weak self] error in
        Task { @MainActor in
          guard let self else { return }
          if let continuation = self.startContinuation {
            self.startContinuation = nil
            self.startTimeout?.cancel()
            self.startTimeout = nil
            if let error {
              self.recorder.delegate = nil
              continuation.resume(throwing: error)
            }
            else { continuation.resume() }
          } else if error == nil {
            await self.cancel()
          }
        }
      }
    }
  }

  func stop() async throws -> URL {
    guard recorder.isRecording else { throw LiveRecordingError.unavailable }
    isStopping = true
    let url = LiveRecordingFile.newURL()
    do {
      try await recorder.stopRecording(withOutput: url)
      recorder.delegate = nil
      isStopping = false
      return url
    } catch {
      recorder.delegate = nil
      isStopping = false
      try? FileManager.default.removeItem(at: url)
      throw error
    }
  }

  func cancel() async {
    startTimeout?.cancel()
    startTimeout = nil
    startContinuation?.resume(throwing: CancellationError())
    startContinuation = nil
    if recorder.isRecording {
      let url = LiveRecordingFile.newURL()
      try? await recorder.stopRecording(withOutput: url)
      try? FileManager.default.removeItem(at: url)
    }
    recorder.delegate = nil
    isStopping = false
  }

  nonisolated func screenRecorder(
    _ screenRecorder: RPScreenRecorder,
    didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?
  ) {
    Task { @MainActor in
      guard !isStopping else { return }
      onInterruption?(error ?? LiveRecordingError.unavailable)
      await cancel()
    }
  }
}
