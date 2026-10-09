import CoreGraphics
import Foundation
import ImageIO
import Observation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum CustomImageError: LocalizedError {
  case tooLarge
  case unreadable
  case unableToSave

  var errorDescription: String? {
    switch self {
    case .tooLarge: "Choose an image smaller than 100 MB."
    case .unreadable: "This image could not be opened. Choose another image."
    case .unableToSave: "The selected image could not be saved on this device."
    }
  }
}

/// Converts an imported image into a bounded, upright PNG before it reaches the Metal renderer.
/// The maximum edge keeps the permanent RGBA texture at or below 16 MiB.
enum CustomImageProcessor {
  static let maxPixelEdge = 2048
  static let maxInputBytes = 100 * 1024 * 1024

  static func normalizedPNG(from data: Data) throws -> Data {
    guard data.count <= maxInputBytes else { throw CustomImageError.tooLarge }
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      throw CustomImageError.unreadable
    }
    return try normalizedPNG(from: source)
  }

  static func normalizedPNG(from url: URL) throws -> Data {
    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
    if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
       size > maxInputBytes { throw CustomImageError.tooLarge }
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
      throw CustomImageError.unreadable
    }
    return try normalizedPNG(from: source)
  }

  private static func normalizedPNG(from source: CGImageSource) throws -> Data {
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelEdge,
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
          image.width > 0, image.height > 0 else { throw CustomImageError.unreadable }
    let result = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      result, UTType.png.identifier as CFString, 1, nil) else {
      throw CustomImageError.unableToSave
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CustomImageError.unableToSave }
    return result as Data
  }

  static func image(from normalizedPNG: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(normalizedPNG as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }
}

@Observable
@MainActor
public final class CustomImageStore {
  public static let shared = CustomImageStore()

  public private(set) var revision = 0
  public private(set) var isUsingCustomImage = false
  public private(set) var isLoading = false
  public private(set) var image: CGImage
  var errorMessage: String?
  private var selectionGeneration = 0
  private let storageURL: URL

  private static var savedURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                        in: .userDomainMask)[0]
    return base.appendingPathComponent("SortSymphony", isDirectory: true)
      .appendingPathComponent("CustomVisualizerImage.png")
  }

  init(storageURL: URL? = nil) {
    self.storageURL = storageURL ?? Self.savedURL
    #if DEBUG
      if ProcessInfo.processInfo.environment["UI_TEST_FRESH_CUSTOM_IMAGE"] == "1" {
        try? FileManager.default.removeItem(at: self.storageURL)
      }
    #endif
    if let data = try? Data(contentsOf: self.storageURL),
       let restored = CustomImageProcessor.image(from: data) {
      image = restored
      isUsingCustomImage = true
    } else {
      image = Self.makeSampleImage()
    }
  }

  func choosePhoto(_ selection: PhotosPickerItem) async {
    selectionGeneration += 1
    let generation = selectionGeneration
    isLoading = true
    defer { if generation == selectionGeneration { isLoading = false } }
    do {
      guard let data = try await selection.loadTransferable(type: Data.self) else {
        throw CustomImageError.unreadable
      }
      let normalized = try await Task.detached(priority: .userInitiated) {
        try CustomImageProcessor.normalizedPNG(from: data)
      }.value
      guard generation == selectionGeneration else { return }
      try install(normalized)
    } catch {
      if generation == selectionGeneration { errorMessage = error.localizedDescription }
    }
  }

  func chooseFile(_ url: URL) async {
    selectionGeneration += 1
    let generation = selectionGeneration
    isLoading = true
    defer { if generation == selectionGeneration { isLoading = false } }
    do {
      let normalized = try await Task.detached(priority: .userInitiated) {
        try CustomImageProcessor.normalizedPNG(from: url)
      }.value
      guard generation == selectionGeneration else { return }
      try install(normalized)
    } catch {
      if generation == selectionGeneration { errorMessage = error.localizedDescription }
    }
  }

  func useSampleImage() {
    selectionGeneration += 1
    isLoading = false
    try? FileManager.default.removeItem(at: storageURL)
    image = Self.makeSampleImage()
    isUsingCustomImage = false
    revision += 1
  }

  private func install(_ data: Data) throws {
    guard let decoded = CustomImageProcessor.image(from: data) else {
      throw CustomImageError.unreadable
    }
    let url = storageURL
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    do { try data.write(to: url, options: .atomic) }
    catch { throw CustomImageError.unableToSave }
    image = decoded
    isUsingCustomImage = true
    revision += 1
    errorMessage = nil
  }

  private static func makeSampleImage() -> CGImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512), format: format)
    let result = renderer.image { context in
      let cg = context.cgContext
      UIColor(red: 0.13, green: 0.30, blue: 0.52, alpha: 1).setFill()
      cg.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
      UIColor(red: 0.97, green: 0.72, blue: 0.30, alpha: 1).setFill()
      cg.fillEllipse(in: CGRect(x: 330, y: 75, width: 115, height: 115))
      UIColor(red: 0.31, green: 0.65, blue: 0.63, alpha: 1).setFill()
      cg.fill(CGRect(x: 0, y: 315, width: 512, height: 197))
      UIColor(red: 0.09, green: 0.47, blue: 0.43, alpha: 1).setFill()
      let mountains = UIBezierPath()
      mountains.move(to: CGPoint(x: 0, y: 360))
      mountains.addLine(to: CGPoint(x: 180, y: 130))
      mountains.addLine(to: CGPoint(x: 385, y: 360))
      mountains.close()
      mountains.fill()
      UIColor(red: 0.76, green: 0.89, blue: 0.83, alpha: 1).setFill()
      let peak = UIBezierPath()
      peak.move(to: CGPoint(x: 125, y: 200))
      peak.addLine(to: CGPoint(x: 180, y: 130))
      peak.addLine(to: CGPoint(x: 245, y: 215))
      peak.close()
      peak.fill()
    }
    return result.cgImage!
  }
}
