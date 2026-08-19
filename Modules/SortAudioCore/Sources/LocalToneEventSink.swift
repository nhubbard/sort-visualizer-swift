import ToneKitDSP
import os

/// Labels the two spots that were, historically, the actual bottleneck behind "recording is fast
/// but playback is slow" symptoms — a per-note `send()` call taking longer than expected, or the
/// gate-closer task waking up far more often than "once per held note" would predict (a
/// regression back toward the fixed per-note `Task` churn `scheduleGateClose`'s own doc comment
/// describes as already-fixed). Moved here verbatim from `AudioEngineKit.AudioService`, which
/// owned this signposting before Phase 2 moved the actual scheduling logic to this type.
private let sinkSignposter = OSSignposter(
  subsystem: "com.nhubbard.Sort2.SortAudioCore", category: "LocalToneEventSink")

/// The in-process `SortAudioEventSink`: maps events via a `ToneMapper` and enqueues the resulting
/// commands directly into a `ToneRenderer`'s command queue — no IPC, no serialization (see
/// Documentation/docs/architecture/audio.md). This is what `AudioEngineKit.AudioService` uses for
/// local playback in the standalone app, and what `SortAudioUnitKit`'s AU extension uses to drain
/// events its bridge client received from the running app; only the caller and the wrapped
/// `ToneRenderer` differ between them.
///
/// `@unchecked Sendable`: safe because exactly one caller drives a given instance's `send(_:
/// noteRange:)` sequentially — `AudioService` calls it only from the main actor, and the AU
/// extension's bridge client calls it only from its own single background dispatch queue; nothing
/// in this codebase shares one `LocalToneEventSink` instance across two concurrent callers. Not
/// enforced by the type itself, same documented-invariant style as `ToneKitDSP`'s `ToneRenderer`/
/// `ToneCommandQueue`.
public final class LocalToneEventSink: SortAudioEventSink, @unchecked Sendable {
  private let renderer: ToneRenderer
  private var mapper = ToneMapper()

  /// Deadline the currently-open gate should close at — updated on every `send(_:noteRange:)`
  /// call. `gateCloserTask`, once running, re-reads this after every wake rather than being torn
  /// down and recreated per event — moved verbatim from `AudioService`'s own previous
  /// `scheduleGateClose`, which existed specifically to avoid a per-note `Task` becoming the
  /// actual throughput ceiling on replay (see git history for the original fix).
  private var nextGateCloseDeadline: ContinuousClock.Instant?
  private var gateCloserTask: Task<Void, Never>?

  public init(renderer: ToneRenderer) {
    self.renderer = renderer
  }

  public func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>) {
    let interval = sinkSignposter.beginInterval("PlayNote", id: sinkSignposter.makeSignpostID())
    defer { sinkSignposter.endInterval("PlayNote", interval) }

    for command in mapper.commands(for: event, noteRange: noteRange) {
      renderer.enqueue(command)
    }
    scheduleGateClose(after: event.holdSeconds)
  }

  /// Pushes `nextGateCloseDeadline` out to `holdSeconds` from now, and — only if no closer is
  /// currently running — starts the one `gateCloserTask` that will ever exist for this sink. An
  /// event arriving mid-hold (the common case at real playback speeds) just moves the deadline; it
  /// never spawns a second `Task`.
  private func scheduleGateClose(after holdSeconds: Double) {
    let deadline = ContinuousClock.now.advanced(by: .seconds(holdSeconds))
    nextGateCloseDeadline = deadline
    guard gateCloserTask == nil else { return }

    gateCloserTask = Task { [weak self] in
      while let self {
        guard let deadline = self.nextGateCloseDeadline else { break }
        let wait = sinkSignposter.beginInterval(
          "GateCloseWait", id: sinkSignposter.makeSignpostID())
        try? await Task.sleep(until: deadline, clock: .continuous)
        sinkSignposter.endInterval("GateCloseWait", wait)
        // A newer event pushed the deadline out while we were asleep — sleep again instead of
        // closing the gate early.
        if let latest = self.nextGateCloseDeadline, latest > deadline { continue }
        self.renderer.enqueue(.closeGate)
        self.nextGateCloseDeadline = nil
        break
      }
      self?.gateCloserTask = nil
    }
  }
}
