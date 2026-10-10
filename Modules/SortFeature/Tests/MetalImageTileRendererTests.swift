import CoreGraphics
import Foundation
import Metal
import SortEngineKit
import Testing
import VisualizationKit

@testable import SortFeature

@MainActor
struct MetalImageTileRendererTests {
  @Test
  func sortedGridReassemblesImageAndSwapMovesTiles() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let source = try #require(makeFourColorImage())
    let renderer = try #require(MetalImageTileRenderer(device: device, sourceImage: source))
    renderer.reset(values: [1, 2, 3, 4], valueRange: 1...4, markers: [:],
                   canvasSize: CGSize(width: 100, height: 100), scale: 1)
    #expect(renderer.debugSourceSlots() == [0, 1, 2, 3])
    let sorted = try renderPixels(renderer, device: device)
    #expect(isColor(sorted, x: 25, y: 25, r: 255, g: 0, b: 0))
    #expect(isColor(sorted, x: 75, y: 25, r: 0, g: 255, b: 0))
    #expect(isColor(sorted, x: 25, y: 75, r: 0, g: 0, b: 255))
    #expect(isColor(sorted, x: 75, y: 75, r: 255, g: 255, b: 0))

    renderer.apply(.swap(0, 3), values: [4, 2, 3, 1], valueRange: 1...4,
                   markers: [:])
    #expect(renderer.debugSourceSlots() == [3, 1, 2, 0])
    let swapped = try renderPixels(renderer, device: device)
    #expect(isColor(swapped, x: 25, y: 25, r: 255, g: 255, b: 0))
    #expect(isColor(swapped, x: 75, y: 75, r: 255, g: 0, b: 0))
  }

  @Test
  func largestSupportedArrayProducesACompleteGrid() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let source = try #require(makeFourColorImage())
    let renderer = try #require(MetalImageTileRenderer(device: device, sourceImage: source))
    let values = Array(1...8192)
    renderer.reset(values: values, valueRange: 1...8192, markers: [:],
                   canvasSize: CGSize(width: 100, height: 100), scale: 1)
    let layout = ImageTileLayout(count: values.count, aspectRatio: 1)
    let slots = renderer.debugSourceSlots()
    #expect(slots.count == layout.cellCount)
    #expect(slots.first == 0)
    #expect(slots[8191] == 8191)
    #expect(slots.last == layout.cellCount - 1)
    _ = try renderPixels(renderer, device: device)
  }

  private func makeFourColorImage() -> CGImage? {
    let bytes: [UInt8] = [
      255, 0, 0, 255, 0, 255, 0, 255,
      0, 0, 255, 255, 255, 255, 0, 255,
    ]
    guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
    return CGImage(width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32,
                   bytesPerRow: 8, space: CGColorSpaceCreateDeviceRGB(),
                   bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                   provider: provider, decode: nil, shouldInterpolate: false,
                   intent: .defaultIntent)
  }

  private func renderPixels(_ renderer: MetalImageTileRenderer,
                            device: MTLDevice) throws -> [UInt8] {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: .bgra8Unorm, width: 100, height: 100, mipmapped: false)
    descriptor.usage = [.renderTarget, .shaderRead]
    let target = try #require(device.makeTexture(descriptor: descriptor))
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = target
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    let queue = try #require(device.makeCommandQueue())
    let command = try #require(queue.makeCommandBuffer())
    renderer.encodeDraw(into: pass, commandBuffer: command)
    command.commit()
    command.waitUntilCompleted()
    var pixels = [UInt8](repeating: 0, count: 100 * 100 * 4)
    target.getBytes(&pixels, bytesPerRow: 100 * 4,
                    from: MTLRegionMake2D(0, 0, 100, 100), mipmapLevel: 0)
    return pixels
  }

  private func isColor(_ pixels: [UInt8], x: Int, y: Int,
                       r: Int, g: Int, b: Int) -> Bool {
    let index = (y * 100 + x) * 4
    return abs(Int(pixels[index + 2]) - r) < 8
      && abs(Int(pixels[index + 1]) - g) < 8
      && abs(Int(pixels[index]) - b) < 8
  }
}
