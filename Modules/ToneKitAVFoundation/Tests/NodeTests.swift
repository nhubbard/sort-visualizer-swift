import AVFoundation
import Testing

@testable import ToneKitAVFoundation

private final class FakeNode: Node {
  let avAudioNode: AVAudioNode = AVAudioMixerNode()
  let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
}

@MainActor
@Suite
struct NodeTests {
  @Test
  func settingOutputAttachesAndConnectsItToTheMainMixer() {
    let engine = AudioEngine()
    let node = FakeNode()

    engine.output = node

    #expect(engine.avEngine.attachedNodes.contains(node.avAudioNode))
    let connections = engine.avEngine.outputConnectionPoints(for: node.avAudioNode, outputBus: 0)
    #expect(connections.contains { $0.node === engine.avEngine.mainMixerNode })
  }

  @Test
  func replacingOutputDisconnectsThePreviousNodeFirst() {
    let engine = AudioEngine()
    let first = FakeNode()
    let second = FakeNode()

    engine.output = first
    engine.output = second

    let firstConnections = engine.avEngine.outputConnectionPoints(for: first.avAudioNode, outputBus: 0)
    #expect(firstConnections.isEmpty, "the previous node should be disconnected, not left dangling")

    let secondConnections = engine.avEngine.outputConnectionPoints(for: second.avAudioNode, outputBus: 0)
    #expect(secondConnections.contains { $0.node === engine.avEngine.mainMixerNode })
  }
}
