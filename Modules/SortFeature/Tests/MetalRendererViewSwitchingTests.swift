import Foundation
import Metal
import MetalKit
import Testing
import VisualizationKit

@testable import SortEngineKit
@testable import SortFeature

/// Regression coverage: `.id(ObjectIdentifier(replay))` at `SortView.canvas(for:)`'s call site
/// keeps `MetalRendererView`'s `Coordinator`/`MTKView` alive across a mid-sort visualizer switch
/// (⌘⇧V, or the Settings picker) — only a genuinely new `replay` tears them down, so
/// `updateUIView` is the only place that can learn the visualizer changed. Fixed by
/// `Coordinator.switchVisualizerIfNeeded`; verified here directly against the `Coordinator`,
/// without needing a live window/screen.
@Suite
struct MetalRendererViewSwitchingTests {
  @MainActor
  @Test
  func switchingVisualizerMidSortRebuildsAndReseedsTheRenderer() throws {
    let header = TapeHeader(
      algorithmID: "test", initialValues: [20, 10, 40, 30], visualSeed: 0,
      compareCount: 0, swapCount: 0, recordingDuration: 0, recordedAt: Date()
    )
    let tape = Tape(
      header: header,
      operations: [.setValue(0, 20), .setValue(1, 10), .setValue(2, 40), .setValue(3, 30)])
    let replay = ReplayEngine(tape: tape)
    for _ in 0..<tape.operations.count { replay.stepForward() }

    let device = try #require(MTLCreateSystemDefaultDevice())
    let view = MTKView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), device: device)
    view.sampleCount = 1

    let coordinator = MetalRendererView.Coordinator()
    let initialRenderer = try #require(MetalBarRenderer(device: device, sampleCount: 1))
    coordinator.setUp(
      replay: replay, renderer: initialRenderer, view: view,
      visualizerID: VisualizerID(rawValue: "bargraph"))
    view.delegate = initialRenderer

    let rainbowID = VisualizerID(rawValue: "rainbow")
    coordinator.switchVisualizerIfNeeded(to: rainbowID, view: view)

    let (trackedID, renderer) = coordinator.debugState()
    #expect(trackedID == rainbowID)

    // The type-level cast alone is unambiguous proof the renderer actually changed — a
    // `MetalBarRenderer` instance (what was there before the switch) would fail it outright.
    let rainbowRenderer = try #require(renderer as? MetalShapeRenderer<RainbowMetalLayout>)
    let instances = rainbowRenderer.debugInstances()
    #expect(instances.count == 4, "the new renderer must have been reset/reseeded, not left empty")

    // Sanity check the seeding reflects the CURRENT frame, not zeroed/garbage memory: value 40
    // (max, at index 2) should be taller than value 10 (min, at index 1).
    #expect(instances[2].size.y > instances[1].size.y)
  }

  /// Switching to the visualizer already active must be a no-op, not a pointless rebuild —
  /// confirmed via object identity, not just behavior, since a silently-rebuilt-but-equivalent
  /// renderer would pass every OTHER assertion here too.
  @MainActor
  @Test
  func switchingToTheSameVisualizerDoesNotRebuild() throws {
    let header = TapeHeader(
      algorithmID: "test", initialValues: [1, 2, 3], visualSeed: 0,
      compareCount: 0, swapCount: 0, recordingDuration: 0, recordedAt: Date()
    )
    let tape = Tape(
      header: header, operations: [.setValue(0, 1), .setValue(1, 2), .setValue(2, 3)])
    let replay = ReplayEngine(tape: tape)

    let device = try #require(MTLCreateSystemDefaultDevice())
    let view = MTKView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), device: device)
    view.sampleCount = 1

    let coordinator = MetalRendererView.Coordinator()
    let initialRenderer = try #require(MetalBarRenderer(device: device, sampleCount: 1))
    let bargraphID = VisualizerID(rawValue: "bargraph")
    coordinator.setUp(
      replay: replay, renderer: initialRenderer, view: view, visualizerID: bargraphID)
    view.delegate = initialRenderer

    coordinator.switchVisualizerIfNeeded(to: bargraphID, view: view)

    let (_, renderer) = coordinator.debugState()
    #expect(renderer as? MetalBarRenderer === initialRenderer)
  }
}
