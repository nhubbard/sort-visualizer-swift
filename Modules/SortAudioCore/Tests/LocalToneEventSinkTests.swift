import Testing
import ToneKitDSP

@testable import SortAudioCore

/// `ToneMapper`'s own mapping/retrigger rules are covered by `ToneMapperTests` — these tests only
/// check what `LocalToneEventSink` adds on top: actually enqueuing into a real `ToneRenderer`, and
/// the deferred gate-close scheduling (moved verbatim from `AudioService`'s old
/// `scheduleGateClose`).
@Suite
struct LocalToneEventSinkTests {
  @Test
  func sendingAnEventProducesAudibleOutput() {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.001))
    renderer.prepare(maxFrameCount: 512)
    let sink = LocalToneEventSink(renderer: renderer)

    sink.send(
      SortToneEvent(
        value: 50, range: 1...100, holdSeconds: 10, index: 0, arraySize: 100,
        operationKind: .compare),
      noteRange: 36...72)

    var left = [Float](repeating: -1, count: 512)
    var right = [Float](repeating: -1, count: 512)
    left.withUnsafeMutableBufferPointer { l in
      right.withUnsafeMutableBufferPointer { r in renderer.render(left: l, right: r, sampleRate: 44100) }
    }
    #expect(!left.allSatisfy { $0 == 0 }, "the gate should already be open by the first render")
  }

  @Test
  func gateClosesOnItsOwnOnceHoldSecondsElapse() async throws {
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(frequency: 440, amplitude: 1),
      envelope: EnvelopeDSP(attackDuration: 0.0001, releaseDuration: 0.0001))
    renderer.prepare(maxFrameCount: 4096)
    let sink = LocalToneEventSink(renderer: renderer)

    sink.send(
      SortToneEvent(
        value: 50, range: 1...100, holdSeconds: 0.05, index: 0, arraySize: 100,
        operationKind: .compare),
      noteRange: 36...72)

    var opened = [Float](repeating: -1, count: 4096)
    var openedRight = [Float](repeating: -1, count: 4096)
    opened.withUnsafeMutableBufferPointer { l in
      openedRight.withUnsafeMutableBufferPointer { r in
        renderer.render(left: l, right: r, sampleRate: 44100)
      }
    }
    #expect(!opened.allSatisfy { $0 == 0 })

    try await Task.sleep(for: .milliseconds(200))  // well past holdSeconds

    var closed = [Float](repeating: -1, count: 4096)
    var closedRight = [Float](repeating: -1, count: 4096)
    for _ in 0..<10 {
      closed.withUnsafeMutableBufferPointer { l in
        closedRight.withUnsafeMutableBufferPointer { r in
          renderer.render(left: l, right: r, sampleRate: 44100)
        }
      }
    }
    #expect(closed.allSatisfy { abs($0) < 0.0001 })
  }
}
