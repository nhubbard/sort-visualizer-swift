import CryptoKit
import Foundation
import Metal
import Testing
import VisualizationKit

@testable import SortEngineKit
@testable import SortFeature

/// Loads `Fixtures/MetalRendererGeometryBaseline.json` via a `#filePath`-relative walk-up rather
/// than a Tuist `testResources`/bundle declaration — same technique
/// `AlgorithmDetailStoreTests.LegacyLoader`/`GrowthModelCalibrationTests` already established for
/// reading loose fixture files straight off the working tree, avoiding any project-manifest
/// changes just to bundle one JSON file.
private enum GeometryBaselineFixture {
  static var url: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // Tests/
      .appendingPathComponent("Fixtures/MetalRendererGeometryBaseline.json")
  }

  static func load() throws -> [String: String] {
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode([String: String].self, from: data)
  }
}

/// Baseline pixel-regression harness for the CPU-to-GPU geometry-layout offload initiative
/// (moving each `MetalShapeLayout`/`MetalTriangleLayout`/bespoke renderer's per-operation
/// `instance(atSlot:...)` math from Swift into the vertex shader). Renders all 15 registered
/// visualizers against one fixed, reproducible scenario and hashes each resulting pixel buffer —
/// same offscreen-texture + `getBytes` readback technique `MetalPolygonRendererTests`/
/// `MetalShapeColorResolutionPixelTests` established, applied as a broad net across the whole
/// canvas instead of a few hand-picked sample points.
///
/// Rendered fresh off `reset()`, not `apply()` — every tracker's `from == to` immediately after a
/// reset (a first-ever paint shows instantly, nothing mid-fade), so the settled pixel output is
/// probe-time-independent and exercises every slot's geometry function in one pass, not just
/// whichever few slots a hand-picked operation sequence would touch.
///
/// A CORRECT geometry port must produce a byte-identical hash to before the port: the settled
/// (post-transition) screen position a layout's formula computes is the same value whether that
/// formula runs on the CPU (today) or the GPU (after porting) — only the ~0.12s transition
/// PATH visibly differs for the 9 sin/cos-based layouts (an accepted, disclosed trade-off; see
/// this initiative's own scoping notes), and this harness never observes mid-transition frames at
/// all. Any hash change here means a real correctness regression (wrong position, wrong color,
/// wrong index mapping), not the accepted cosmetic difference.
///
/// **Usage**: run this suite once before starting a layout port and record the printed
/// `HASH visualizerID=... sha256=...` lines as the baseline (e.g. paste into a scratch file or
/// this suite's own git history). After porting a given visualizer, re-run and confirm ITS hash
/// is unchanged (a real geometry bug would change it) and every OTHER visualizer's hash is ALSO
/// unchanged (confirms the port didn't leak into shared code paths like `AnimatedField.h` or
/// `MetalAnimationUniforms`).
@Suite
struct MetalRendererGeometryBaselineTests {
  private static let width = 400
  private static let height = 300
  private static let scale: CGFloat = 2
  private static let count = 64
  // A fixed multiplicative permutation of 1...64 (17 is coprime with 64, so this is a genuine
  // bijection) — exercises every layout's real index/value math across the whole range, unlike
  // an already-sorted or simply-reversed array, which some layouts special-case away accidentally.
  private static let values: [Int] = (0..<count).map { ($0 * 17) % count + 1 }
  // A couple of marked indices exercise `MetalShapeColor.markerKind`'s primary/secondary path
  // too, not just the unmarked hue-ramp/neutral path every slot would otherwise take.
  private static let markers: [Int: Set<Int>] = [
    5: [Marker.primary], 40: [Marker.secondary],
  ]

  /// Every `VisualizerID` raw value `MetalRendererFactory` recognizes — kept as a literal list
  /// (not read from `VisualizerRegistry`) so this suite has zero dependency on app-launch-time
  /// registration order and stays exhaustive by construction: adding a 16th case to the factory's
  /// switch without adding it here is a visible gap in this list, not a silent skip.
  private static let visualizerIDs = [
    "bargraph", "disparitybargraph", "pixelmesh", "rainbow", "sinewave", "disparitydots",
    "hoopstack", "scatterplot", "spiraldots", "wavedots", "colorcircle", "disparitycircle",
    "spiral", "disparitychords", "hanoitowers",
  ]

  @MainActor
  @Test(arguments: visualizerIDs)
  func settledPixelHash(visualizerID: String) throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(
      MetalRendererFactory.makeRenderer(
        for: VisualizerID(rawValue: visualizerID), device: device, sampleCount: 1),
      "no renderer registered for \(visualizerID) — factory/this list have drifted apart")
    let encodable = try #require(
      renderer as? OffscreenEncodable,
      "\(type(of: renderer)) must conform to OffscreenEncodable for this harness to render it")

    renderer.reset(
      values: Self.values, valueRange: 1...Self.count, markers: Self.markers,
      canvasSize: CGSize(width: Self.width, height: Self.height), scale: Self.scale)

    let pixels = try render(encodable, device: device)
    let digest = SHA256.hash(data: Data(pixels))
    let hex = digest.map { String(format: "%02x", $0) }.joined()

    let baseline = try GeometryBaselineFixture.load()
    guard let expected = baseline[visualizerID] else {
      // A visualizer added to the factory after the fixture was last regenerated — not a
      // regression (nothing to regress against yet), just a gap to close. Loud enough to notice,
      // not a hard failure.
      let fixtureName = GeometryBaselineFixture.url.lastPathComponent
      Issue.record("no baseline recorded for \(visualizerID) yet — add sha256=\(hex) to \(fixtureName)")
      return
    }
    #expect(
      hex == expected,
      """
      \(visualizerID)'s settled-state pixel output changed.
      expected sha256=\(expected)
      actual   sha256=\(hex)
      A correct geometry-layout port must produce byte-identical settled pixels to before the \
      port — see this file's own doc comment. If this change is actually intended (a real bug \
      fix, not the port), update Fixtures/MetalRendererGeometryBaseline.json deliberately.
      """)
  }

  @MainActor
  private func render(_ renderer: some OffscreenEncodable, device: MTLDevice) throws -> [UInt8] {
    let pixelWidth = Int(Double(Self.width) * Self.scale)
    let pixelHeight = Int(Double(Self.height) * Self.scale)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: pixelWidth, height: pixelHeight, mipmapped: false)
    descriptor.usage = [.renderTarget, .shaderRead]
    descriptor.storageMode = .shared
    let texture = try #require(device.makeTexture(descriptor: descriptor))

    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = texture
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    passDescriptor.colorAttachments[0].storeAction = .store

    let queue = try #require(device.makeCommandQueue())
    let commandBuffer = try #require(queue.makeCommandBuffer())
    renderer.encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    #expect(commandBuffer.error == nil)

    let bytesPerRow = pixelWidth * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * pixelHeight)
    texture.getBytes(
      &pixels, bytesPerRow: bytesPerRow, from: MTLRegionMake2D(0, 0, pixelWidth, pixelHeight),
      mipmapLevel: 0)
    return pixels
  }
}

// `MetalPolygonRendererTests.swift` already declares `OffscreenEncodable` and conforms
// `MetalTriangleRenderer`/`MetalDisparityChordsRenderer` to it — extend the remaining 3 concrete
// renderer types here rather than duplicating the protocol under a different name.
extension MetalBarRenderer: OffscreenEncodable {}
extension MetalShapeRenderer: OffscreenEncodable {}
extension MetalHanoiTowersRenderer: OffscreenEncodable {}
