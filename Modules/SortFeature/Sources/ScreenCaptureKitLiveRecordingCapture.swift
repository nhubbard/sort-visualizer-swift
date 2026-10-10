#if targetEnvironment(macCatalyst)
import Foundation
@preconcurrency import ScreenCaptureKit

@available(macCatalyst 18.2, *)
@MainActor
final class ScreenCaptureKitLiveRecordingCapture: NSObject, LiveRecordingCapturing,
  SCContentSharingPickerObserver, SCRecordingOutputDelegate, SCStreamDelegate {
  var onInterruption: ((Error) -> Void)?

  private var startContinuation: CheckedContinuation<Void, Error>?
  private var finishContinuation: CheckedContinuation<Void, Error>?
  private var stream: SCStream?
  private var output: SCRecordingOutput?
  private var outputURL: URL?
  private var isStopping = false

  func start() async throws {
    guard stream == nil, startContinuation == nil else { return }
    try await withCheckedThrowingContinuation { continuation in
      startContinuation = continuation
      Task {
        let filter = await currentWindowFilter()
        guard startContinuation != nil else { return }
        if let filter {
          await beginStream(with: filter)
        } else {
          presentWindowPicker()
        }
      }
    }
  }

  /// A single normal window owned by this process is unambiguous. If the app has multiple
  /// windows, let the system picker identify the one the person meant to record.
  private func currentWindowFilter() async -> SCContentFilter? {
    guard let content = try? await SCShareableContent.currentProcess else { return nil }
    let ownWindows = content.windows.filter { window in
      window.owningApplication?.processID == ProcessInfo.processInfo.processIdentifier
        && window.isOnScreen && window.windowLayer == 0
        && window.frame.width > 0 && window.frame.height > 0
    }
    guard ownWindows.count == 1, let window = ownWindows.first else { return nil }
    return SCContentFilter(desktopIndependentWindow: window)
  }

  private func presentWindowPicker() {
    let picker = SCContentSharingPicker.shared
    picker.add(self)
    var pickerConfiguration = SCContentSharingPickerConfiguration()
    pickerConfiguration.allowedPickerModes = .singleWindow
    picker.defaultConfiguration = pickerConfiguration
    picker.isActive = true
    picker.present(using: .window)
  }

  func stop() async throws -> URL {
    guard let stream, let output, let outputURL else { throw LiveRecordingError.unavailable }
    isStopping = true
    do {
      try await withCheckedThrowingContinuation { continuation in
        finishContinuation = continuation
        do { try stream.removeRecordingOutput(output) }
        catch {
          finishContinuation = nil
          continuation.resume(throwing: error)
        }
      }
      try await stream.stopCapture()
      clearCapture()
      return outputURL
    } catch {
      await cancel()
      throw error
    }
  }

  func cancel() async {
    startContinuation?.resume(throwing: CancellationError())
    startContinuation = nil
    finishContinuation?.resume(throwing: CancellationError())
    finishContinuation = nil
    if let stream { try? await stream.stopCapture() }
    if let outputURL { try? FileManager.default.removeItem(at: outputURL) }
    clearCapture()
  }

  private func clearCapture() {
    let picker = SCContentSharingPicker.shared
    picker.remove(self)
    picker.isActive = false
    stream = nil
    output = nil
    outputURL = nil
    isStopping = false
  }

  private func beginStream(with filter: SCContentFilter) async {
    guard startContinuation != nil else { return }
    do {
      let configuration = SCStreamConfiguration()
      let scale = CGFloat(filter.pointPixelScale)
      configuration.width = max(2, Int(filter.contentRect.width * scale) & ~1)
      configuration.height = max(2, Int(filter.contentRect.height * scale) & ~1)
      configuration.capturesAudio = true
      configuration.excludesCurrentProcessAudio = false

      let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
      let url = LiveRecordingFile.newURL()
      let outputConfiguration = SCRecordingOutputConfiguration()
      outputConfiguration.outputURL = url
      let output = SCRecordingOutput(configuration: outputConfiguration, delegate: self)
      try stream.addRecordingOutput(output)
      self.stream = stream
      self.output = output
      outputURL = url
      try await stream.startCapture()
      startContinuation?.resume()
      startContinuation = nil
    } catch {
      startContinuation?.resume(throwing: error)
      startContinuation = nil
      await cancel()
    }
  }

  nonisolated func contentSharingPicker(
    _ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?
  ) {
    Task { @MainActor in await beginStream(with: filter) }
  }

  nonisolated func contentSharingPicker(
    _ picker: SCContentSharingPicker, didCancelFor stream: SCStream?
  ) {
    Task { @MainActor in await cancel() }
  }

  nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
    Task { @MainActor in
      startContinuation?.resume(throwing: error)
      startContinuation = nil
      await cancel()
    }
  }

  nonisolated func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
    Task { @MainActor in
      finishContinuation?.resume()
      finishContinuation = nil
    }
  }

  nonisolated func recordingOutput(
    _ recordingOutput: SCRecordingOutput, didFailWithError error: Error
  ) {
    Task { @MainActor in
      if let finishContinuation {
        self.finishContinuation = nil
        finishContinuation.resume(throwing: error)
      } else {
        onInterruption?(error)
        await cancel()
      }
    }
  }

  nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
    Task { @MainActor in
      guard !isStopping else { return }
      onInterruption?(error)
      await cancel()
    }
  }
}
#endif
