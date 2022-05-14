//
//  FMSynth.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/2/22.
//

import AVFoundation
import Foundation

// The maximum number of audio buffers in flight. Setting to two allows one
// buffer to be played while the next is being written.
let kInFlightAudioBuffers: Int = 2

// The number of audio samples per buffer. A lower value reduces latency for
// changes but requires more processing but increases the risk of being unable
// to fill the buffers in time. A setting of 1024 represents about 23ms of
// samples.
let kSamplesPerBuffer: AVAudioFrameCount = 1024

class FMSynthesizer {
    // The audio engine manages the sound system.
    private let engine: AVAudioEngine = AVAudioEngine()

    // The player node schedules the playback of the audio buffers.
    private let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()

    // Use standard non-interleaved PCM audio.
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)

    // A circular queue of audio buffers.
    private var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()

    // The index of the next buffer to fill.
    private var bufferIndex: Int = 0

    // The dispatch queue to render audio samples.
    private let audioQueue: DispatchQueue = DispatchQueue(label: "FMSynthesizerQueue")

    // A semaphore to gate the number of buffers processed.
    private let audioSemaphore: DispatchSemaphore = DispatchSemaphore(value: kInFlightAudioBuffers)

    init() {
        // Create a pool of audio buffers.
        for _ in 0..<kInFlightAudioBuffers {
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: kSamplesPerBuffer)!
            audioBuffers.append(audioBuffer)
        }

        // Attach and connect the player node.
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)
        do {
            try engine.start()
            NotificationCenter.default.addObserver(self, selector: #selector(self.audioEngineConfigurationChange), name: NSNotification.Name.AVAudioEngineConfigurationChange, object: engine)
        } catch {
            print("Failed to start AVAudioEngine!")
        }
    }

    public func play(carrierFrequency: Float32, modulatorFrequency: Float32 = 679.0, modulatorAmplitude: Float32 = 0.8, duration: Int = 5) {
        let unitVelocity = Float32(2.0 * .pi / audioFormat!.sampleRate)
        let carrierVelocity = carrierFrequency * unitVelocity
        let modulatorVelocity = modulatorFrequency * unitVelocity
        audioQueue.async() {
            var sampleTime: Float32 = 0
            // Previously, the tone would play forever; this prevents the tone from playing indefinitely.
            //for _ in 0..<duration {
                // Wait for a buffer to become available.
                _ = self.audioSemaphore.wait(timeout: DispatchTime.distantFuture)
                // dispatch_semaphore_wait(self.audioSemaphore, DISPATCH_TIME_FOREVER)

                // Fill the buffer with new samples.
                let audioBuffer = self.audioBuffers[self.bufferIndex]
                let leftChannel = audioBuffer.floatChannelData![0]
                let rightChannel = audioBuffer.floatChannelData![1]
                for sampleIndex in 0..<Int(kSamplesPerBuffer) {
                    let sample = sin(carrierVelocity * sampleTime + modulatorAmplitude * sin(modulatorVelocity * sampleTime))
                    leftChannel[sampleIndex] = sample
                    rightChannel[sampleIndex] = sample
                    sampleTime += 1
                }
                audioBuffer.frameLength = kSamplesPerBuffer

                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
                self.playerNode.scheduleBuffer(audioBuffer) {
                    self.audioSemaphore.signal()
                    return
                }

                self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
            //}
        }

        playerNode.pan = 0.8
        playerNode.play()
    }

    @objc func audioEngineConfigurationChange(notification: NSNotification) -> Void {
        NSLog("Audio engine configuration change: \(notification)")
    }
}
