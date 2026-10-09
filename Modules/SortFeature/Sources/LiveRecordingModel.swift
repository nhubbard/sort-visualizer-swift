import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
protocol LiveRecordingCapturing: AnyObject {
  var onInterruption: ((Error) -> Void)? { get set }
  func start() async throws
  func stop() async throws -> URL
  func cancel() async
}

enum LiveRecordingError: LocalizedError {
  case unavailable
  case emptyFile
  case startTimedOut

  var errorDescription: String? {
    switch self {
    case .unavailable:
      String(localized: "Screen recording is unavailable on this device right now.", bundle: .module)
    case .emptyFile:
      String(localized: "The recording did not produce a video. Please try again.", bundle: .module)
    case .startTimedOut:
      String(localized: "Screen recording did not start. Check system recording permissions and try again.", bundle: .module)
    }
  }
}

enum LiveRecordingPhase: Equatable {
  case idle
  case choosing
  case recording
  case saving
  case ready(URL)
  case failed(String)
}

/// The UI state is independent of ScreenCaptureKit and ReplayKit so failure, interruption,
/// cancellation, and duplicate-button behavior can be exercised without a system picker.
@Observable
@MainActor
final class LiveRecordingModel {
  private(set) var phase: LiveRecordingPhase = .idle
  private(set) var isUsingFallback = false
  private var capture: any LiveRecordingCapturing
  private var generation = 0

  init(capture: any LiveRecordingCapturing) {
    self.capture = capture
    observeInterruption()
  }

  private func observeInterruption() {
    capture.onInterruption = { [weak self] error in
      self?.generation += 1
      self?.phase = .failed(error.localizedDescription)
    }
  }

  func startUsing(_ replacement: any LiveRecordingCapturing) async {
    guard phase == .choosing else { return }
    generation += 1
    phase = .idle
    let previous = capture
    previous.onInterruption = nil
    await previous.cancel()
    capture = replacement
    isUsingFallback = true
    observeInterruption()
    await start()
  }

  func start() async {
    guard phase != .choosing && phase != .recording && phase != .saving else { return }
    generation += 1
    let current = generation
    phase = .choosing
    do {
      try await capture.start()
      if current == generation { phase = .recording }
    } catch is CancellationError {
      if current == generation { phase = .idle }
    } catch {
      if current == generation { phase = .failed(error.localizedDescription) }
    }
  }

  func stop() async {
    guard phase == .recording else { return }
    generation += 1
    let current = generation
    phase = .saving
    do {
      let url = try await capture.stop()
      guard FileManager.default.fileExists(atPath: url.path),
        let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0
      else { throw LiveRecordingError.emptyFile }
      if current == generation { phase = .ready(url) }
    } catch {
      if current == generation { phase = .failed(error.localizedDescription) }
    }
  }

  func cancel() async {
    generation += 1
    let shouldCancel = phase == .choosing || phase == .recording || phase == .saving
    if shouldCancel { phase = .idle }
    if shouldCancel { await capture.cancel() }
  }
}

enum LiveRecordingFile {
  static func newURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("SortSymphony-\(UUID().uuidString)", conformingTo: .mpeg4Movie)
  }
}
