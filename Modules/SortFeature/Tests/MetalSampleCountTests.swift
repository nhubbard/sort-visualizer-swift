import Metal
import Testing

@testable import SortFeature

@Suite
struct MetalSampleCountTests {
  @Test
  func preferredReturnsAValueTheDeviceActuallySupports() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let result = MetalSampleCount.preferred(for: device)
    #expect([1, 2, 4, 8].contains(result))
    #expect(device.supportsTextureSampleCount(result))
  }

  @Test
  func preferredNeverReturnsLessThanOneSample() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    #expect(MetalSampleCount.preferred(for: device) >= 1)
  }
}
