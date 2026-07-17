// This file's `Node`/`AudioEngine` shape is modeled on AudioKit (github.com/AudioKit/AudioKit),
// trimmed to the one thing this module needs — attaching a single terminal node's underlying
// `AVAudioNode` to an `AVAudioEngine`'s mixer — rather than AudioKit's general dynamic node graph
// (`connections`, `bypass`, MIDI scheduling), which this module never needs since it only ever has
// one linear chain (`Oscillator` feeding `AmplitudeEnvelope`). See this module's NOTICE.md.
//
// Used under the MIT License:
//
// MIT License
//
// Copyright (c) 2016 Aurelius Prochazka (AudioKit)
// Copyright (c) 2021 AudioKit (AudioKitEX, SoundpipeAudioKit)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AVFoundation

/// A node this module can attach to an `AudioEngine`'s output. Real AudioKit's `Node` also exposes
/// `connections` (for an arbitrary dynamic graph) and MIDI scheduling — dropped here since this
/// module never builds anything but one fixed chain.
public protocol Node: AnyObject {
  var avAudioNode: AVAudioNode { get }
  var outputFormat: AVAudioFormat { get }
}

/// Thin wrapper around `AVAudioEngine`, matching AudioKit's own `AudioEngine` shape closely enough
/// that `AudioService` only had to change its imports, not its call sites.
@MainActor
public final class AudioEngine {
  public let avEngine = AVAudioEngine()

  /// Setting this attaches and connects the node's `avAudioNode` to `avEngine`'s main mixer,
  /// disconnecting whatever was previously attached first.
  public var output: (any Node)? {
    didSet {
      if let oldValue { avEngine.disconnectNodeOutput(oldValue.avAudioNode) }
      guard let output else { return }
      avEngine.attach(output.avAudioNode)
      avEngine.connect(output.avAudioNode, to: avEngine.mainMixerNode, format: output.outputFormat)
    }
  }

  public init() {}

  public func start() throws {
    try avEngine.start()
  }

  public func stop() {
    avEngine.stop()
  }
}
