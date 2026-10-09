import Foundation
import Testing

@testable import SortFeature

@MainActor
@Suite
struct LiveRecordingModelTests {
  @Test
  func successfulRecordingCanBePreviewedAndShared() async throws {
    let capture = FakeCapture()
    let url = LiveRecordingFile.newURL()
    defer { try? FileManager.default.removeItem(at: url) }
    try Data([0, 1, 2, 3]).write(to: url)
    capture.outputURL = url
    let model = LiveRecordingModel(capture: capture)

    await model.start()
    #expect(model.phase == .recording)
    await model.start()
    #expect(capture.startCount == 1)
    await model.stop()
    #expect(model.phase == .ready(url))
    #expect(capture.stopCount == 1)
  }

  @Test
  func emptyOutputShowsRecoverableFailure() async throws {
    let capture = FakeCapture()
    let url = LiveRecordingFile.newURL()
    defer { try? FileManager.default.removeItem(at: url) }
    try Data().write(to: url)
    capture.outputURL = url
    let model = LiveRecordingModel(capture: capture)

    await model.start()
    await model.stop()
    guard case .failed(let message) = model.phase else {
      Issue.record("Expected an empty-video error")
      return
    }
    #expect(message.contains("did not produce"))
    await model.start()
    #expect(model.phase == .recording)
  }

  @Test
  func pickerCancellationAndCaptureInterruptionAreHandled() async {
    let capture = FakeCapture()
    capture.waitForSelection = true
    let model = LiveRecordingModel(capture: capture)
    let starting = Task { await model.start() }
    await Task.yield()
    #expect(model.phase == .choosing)
    await model.cancel()
    await starting.value
    #expect(model.phase == .idle)
    #expect(capture.cancelCount == 1)

    capture.waitForSelection = false
    await model.start()
    #expect(model.phase == .recording)
    capture.onInterruption?(TestError.interrupted)
    #expect(model.phase == .failed("Recording was interrupted"))
  }

  @Test
  func permissionFailureCanBeRetried() async {
    let capture = FakeCapture()
    capture.startError = TestError.denied
    let model = LiveRecordingModel(capture: capture)

    await model.start()
    #expect(model.phase == .failed("Screen recording permission was denied"))
    capture.startError = nil
    await model.start()
    #expect(model.phase == .recording)
    #expect(capture.startCount == 2)
  }

  @Test
  func missingOutputFailsWithoutOfferingShare() async {
    let capture = FakeCapture()
    let model = LiveRecordingModel(capture: capture)

    await model.start()
    await model.stop()
    #expect(model.phase == .failed(LiveRecordingError.emptyFile.localizedDescription))
    #expect(capture.stopCount == 1)
  }

  @Test
  func fallbackReplacesAnUnresponsivePicker() async {
    let picker = FakeCapture()
    picker.waitForSelection = true
    let fallback = FakeCapture()
    let model = LiveRecordingModel(capture: picker)
    let starting = Task { await model.start() }
    await Task.yield()

    await model.startUsing(fallback)
    await starting.value
    #expect(picker.cancelCount == 1)
    #expect(fallback.startCount == 1)
    #expect(model.isUsingFallback)
    #expect(model.phase == .recording)
  }

  private enum TestError: LocalizedError {
    case interrupted
    case denied
    var errorDescription: String? {
      switch self {
      case .interrupted: "Recording was interrupted"
      case .denied: "Screen recording permission was denied"
      }
    }
  }

  @MainActor
  private final class FakeCapture: LiveRecordingCapturing {
    var onInterruption: ((Error) -> Void)?
    var outputURL = URL(fileURLWithPath: "/missing.mp4")
    var waitForSelection = false
    var startError: Error?
    var startCount = 0
    var stopCount = 0
    var cancelCount = 0
    private var selection: CheckedContinuation<Void, Error>?

    func start() async throws {
      startCount += 1
      if let startError { throw startError }
      if waitForSelection {
        try await withCheckedThrowingContinuation { selection = $0 }
      }
    }

    func stop() async throws -> URL {
      stopCount += 1
      return outputURL
    }

    func cancel() async {
      cancelCount += 1
      selection?.resume(throwing: CancellationError())
      selection = nil
    }
  }
}
