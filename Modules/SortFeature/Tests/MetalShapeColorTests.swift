import SortEngineKit
import Testing

@testable import SortFeature

@Suite
struct MetalShapeColorTests {
  @Test
  func normalizedAtLowerBoundIsZero() {
    #expect(MetalShapeColor.normalized(value: 10, in: 10...20) == 0.0)
  }

  @Test
  func normalizedAtUpperBoundIsOne() {
    #expect(MetalShapeColor.normalized(value: 20, in: 10...20) == 1.0)
  }

  @Test
  func normalizedWithAZeroSpanRangeReturnsOneRatherThanDividingByZero() {
    #expect(MetalShapeColor.normalized(value: 5, in: 5...5) == 1.0)
  }

  @Test
  func markerReturnsPrimaryColorWhenIndexCarriesThePrimaryMarker() {
    let markers: [Int: Set<Int>] = [0: [Marker.primary]]
    #expect(MetalShapeColor.marker(forIndex: 0, in: markers) == MetalShapeColor.primary)
  }

  @Test
  func markerReturnsSecondaryColorWhenIndexCarriesTheSecondaryMarker() {
    let markers: [Int: Set<Int>] = [0: [Marker.secondary]]
    #expect(MetalShapeColor.marker(forIndex: 0, in: markers) == MetalShapeColor.secondary)
  }

  @Test
  func markerReturnsNilWhenIndexHasNoEntryAtAll() {
    let markers: [Int: Set<Int>] = [1: [Marker.primary]]
    #expect(MetalShapeColor.marker(forIndex: 0, in: markers) == nil)
  }
}
