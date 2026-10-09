import CoreGraphics
import Foundation
import Testing
import UIKit

@testable import SettingsKit

struct CustomImageProcessorTests {
  @Test
  func largeImageIsDownsampledBeforeStorage() throws {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(
      size: CGSize(width: 4096, height: 512), format: format)
    let input = renderer.pngData { context in
      UIColor.systemBlue.setFill()
      context.cgContext.fill(CGRect(x: 0, y: 0, width: 4096, height: 512))
    }
    let normalized = try CustomImageProcessor.normalizedPNG(from: input)
    let image = try #require(CustomImageProcessor.image(from: normalized))
    #expect(image.width == CustomImageProcessor.maxPixelEdge)
    #expect(image.height == 256)
  }

  @Test
  func malformedImageIsRejected() {
    #expect(throws: CustomImageError.self) {
      try CustomImageProcessor.normalizedPNG(from: Data("not an image".utf8))
    }
  }

  @MainActor
  @Test
  func chosenFileSurvivesRelaunchAndSampleRemovesIt() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appendingPathComponent("source.png")
    let saved = directory.appendingPathComponent("stored.png")
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 6), format: format)
    let input = renderer.pngData { context in
      UIColor.systemRed.setFill()
      context.cgContext.fill(CGRect(x: 0, y: 0, width: 8, height: 6))
    }
    try input.write(to: source)

    let store = CustomImageStore(storageURL: saved)
    await store.chooseFile(source)
    #expect(store.errorMessage == nil)
    #expect(store.isUsingCustomImage)
    #expect(store.revision == 1)
    #expect(store.image.width == 8)
    #expect(FileManager.default.fileExists(atPath: saved.path))

    let restored = CustomImageStore(storageURL: saved)
    #expect(restored.isUsingCustomImage)
    #expect(restored.image.width == 8)
    restored.useSampleImage()
    #expect(!restored.isUsingCustomImage)
    #expect(!FileManager.default.fileExists(atPath: saved.path))
  }
}
