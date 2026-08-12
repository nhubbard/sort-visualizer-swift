import AlgorithmKit
import Foundation
import SortEngineKit

/// Just enough per-operation state for audio: the array's current raw values and how far through
/// the tape playback has gotten. Deliberately **not** `SortEngineKit.ReplayEngine.PlaybackState`/
/// `BarState`, which carry a `UUID`/marker `Set`/`isSorted` per slot for `SortView`'s benefit —
/// none of that is meaningful to audio, which only ever needs "what value sits at index i right
/// now" (AUDIO_UNIT_PLAN.md §7's correction to the plan's original "drives ReplayEngine" wording).
private struct HeadlessPlaybackState {
  var values: [Int]
  var stepIndex: Int = 0
}

/// Runs a full shuffle+sort tape to completion with no `SortSession`/UI in the loop, emitting
/// `SortToneEvent`s to a `SortAudioEventSink` as it goes — the "headless algorithm/replay driver"
/// `AUDIO_UNIT_PLAN.md` §7 describes, for a future AU extension that has no app UI feeding it
/// choices. Depends only on `SortEngineKit`/`AlgorithmKit` (via `TapeFactory`) — never `SortFeature`.
///
/// Which algorithm/shuffle/size to run, and whether to loop afterward, is entirely the caller's
/// decision (mirroring `SortSession` itself never picking its own algorithm) — out of scope here.
public final class HeadlessSortAudioDriver {
  private let sink: any SortAudioEventSink
  private let noteRange: ClosedRange<Int>

  /// Flat operations-per-second pacing, analogous to `ReplayEngine.speed` — a live knob, re-read
  /// every tick. There's no fixed-duration-pacing mode here: that concept exists in `ReplayEngine`
  /// for "watch a sort finish in exactly N seconds" on screen, which doesn't apply to a
  /// continuous, ambient audio generator.
  public var speed: Double = 30.0

  /// How often to check for due operations. There's no display to vsync-lock to in a headless
  /// context, so a plain sleep interval (matching `ReplayEngine`'s own display-refresh-rate tick
  /// cadence in spirit, not in mechanism) is the honest equivalent — a deliberate, documented
  /// difference from `ReplayEngine.play()`'s `CADisplayLink`-driven ticks.
  private static let tickInterval = Duration.milliseconds(16)

  public init(sink: any SortAudioEventSink, noteRange: ClosedRange<Int>) {
    self.sink = sink
    self.noteRange = noteRange
  }

  /// Records `algorithm`/`shuffle` at `size` (see `TapeFactory.makeTape`), then walks the
  /// resulting tape to completion, sending one `SortToneEvent` per touched index on `.compare`/
  /// `.swap`/`.setValue` — exactly the three cases `SortSession.makeOnStepClosure` reacts to for
  /// audio today. Returns once the tape is fully played, or throws if cancelled or if recording
  /// exceeded `operationCap` (see `TapeRecordingError`).
  public func run(
    algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int, operationCap: Int
  ) async throws {
    let tape = try TapeFactory.makeTape(
      algorithm: algorithm, shuffle: shuffle, size: size, operationCap: operationCap)
    var state = HeadlessPlaybackState(values: tape.header.initialValues)
    var accumulator = 0.0
    var lastTick = ContinuousClock.now

    while state.stepIndex < tape.operations.count {
      try Task.checkCancellation()
      try await Task.sleep(for: Self.tickInterval)
      let now = ContinuousClock.now
      let elapsed = lastTick.duration(to: now).timeInterval
      lastTick = now

      let remaining = tape.operations.count - state.stepIndex
      let currentSpeed = speed
      let opsToApply = ReplayEngine.opsToApply(
        elapsed: elapsed, speed: currentSpeed, accumulator: &accumulator, remaining: remaining)
      guard opsToApply > 0 else { continue }

      let holdSeconds = max(1.0 / currentSpeed, 0.03)
      for _ in 0..<opsToApply {
        guard state.stepIndex < tape.operations.count else { break }
        apply(tape.operations[state.stepIndex], to: &state, holdSeconds: holdSeconds)
      }
    }
  }

  private func apply(_ operation: SortOperation, to state: inout HeadlessPlaybackState, holdSeconds: Double) {
    switch operation {
    case .swap(let i, let j):
      state.values.swapAt(i, j)
      emit(state.values[i], count: state.values.count, holdSeconds: holdSeconds)
      emit(state.values[j], count: state.values.count, holdSeconds: holdSeconds)
    case .setValue(let i, let value):
      state.values[i] = value
      emit(state.values[i], count: state.values.count, holdSeconds: holdSeconds)
    case .compare(let i, let j):
      emit(state.values[i], count: state.values.count, holdSeconds: holdSeconds)
      emit(state.values[j], count: state.values.count, holdSeconds: holdSeconds)
    default:
      break  // markers/aux/reversal don't affect audio-relevant array values.
    }
    state.stepIndex += 1
  }

  private func emit(_ value: Int, count: Int, holdSeconds: Double) {
    sink.send(
      SortToneEvent(value: value, range: 1...count, holdSeconds: holdSeconds),
      noteRange: noteRange)
  }
}

extension Duration {
  fileprivate var timeInterval: TimeInterval {
    Double(components.seconds) + Double(components.attoseconds) / 1e18
  }
}
