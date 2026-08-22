import Metal
import Testing
import VisualizationKit

@testable import SortFeature

@Suite
struct MetalRendererFactoryTests {
  @MainActor
  @Test
  func knownVisualizerIDsResolveToTheirExpectedConcreteRendererType() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    #expect(
      MetalRendererFactory.makeRenderer(
        for: VisualizerID(rawValue: "bargraph"), device: device, sampleCount: 1)
        is MetalBarRenderer)
    #expect(
      MetalRendererFactory.makeRenderer(
        for: VisualizerID(rawValue: "hanoitowers"), device: device, sampleCount: 1)
        is MetalHanoiTowersRenderer)
    // The one renderer with no dedicated behavioral test file of its own today — this at least
    // confirms the factory constructs a real, working instance for it.
    #expect(
      MetalRendererFactory.makeRenderer(
        for: VisualizerID(rawValue: "disparitychords"), device: device, sampleCount: 1)
        is MetalDisparityChordsRenderer)
  }

  @MainActor
  @Test
  func unknownVisualizerIDReturnsNilRatherThanCrashing() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = MetalRendererFactory.makeRenderer(
      for: VisualizerID(rawValue: "not-a-real-visualizer"), device: device, sampleCount: 1)
    #expect(renderer == nil)
  }
}
