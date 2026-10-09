import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// The same image choice controls appear beside the live visualizer picker and in Settings.
public struct CustomImagePickerControls: View {
  public enum Presentation {
    case form
    case inline
  }

  @State private var store = CustomImageStore.shared
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var isFileImporterPresented = false
  private let presentation: Presentation

  public init(presentation: Presentation = .form) {
    self.presentation = presentation
  }

  public var body: some View {
    Group {
      switch presentation {
      case .form:
        photoButton
        fileButton
        if store.isUsingCustomImage { sampleButton }
        LabeledContent(String(localized: "Source", bundle: .module)) { sourceStatus }
      case .inline:
        HStack(spacing: 8) {
          photoButton
          fileButton
          if store.isUsingCustomImage { sampleButton }
          sourceStatus
        }
        .buttonStyle(.bordered)
      }
    }
    .onChange(of: selectedPhoto) { _, photo in
      guard let photo else { return }
      Task { await store.choosePhoto(photo) }
    }
    .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.image]) { result in
      switch result {
      case .success(let url): Task { await store.chooseFile(url) }
      case .failure(let error): store.errorMessage = error.localizedDescription
      }
    }
    .alert(String(localized: "Image Unavailable", bundle: .module), isPresented: Binding(
      get: { store.errorMessage != nil },
      set: { if !$0 { store.errorMessage = nil } }
    )) {
      Button(String(localized: "OK", bundle: .module)) { store.errorMessage = nil }
    } message: {
      Text(store.errorMessage ?? String(localized: "Choose another image.", bundle: .module))
    }
  }

  private var photoButton: some View {
    PhotosPicker(selection: $selectedPhoto, matching: .images) {
      Label(String(localized: "Choose Photo", bundle: .module), systemImage: "photo.on.rectangle")
    }
    .accessibilityIdentifier("customImageChoosePhoto")
  }

  private var fileButton: some View {
    Button {
      isFileImporterPresented = true
    } label: {
      Label(String(localized: "Choose File", bundle: .module), systemImage: "folder")
    }
    .accessibilityIdentifier("customImageChooseFile")
  }

  private var sampleButton: some View {
    Button(String(localized: "Use Sample Image", bundle: .module)) { store.useSampleImage() }
      .accessibilityIdentifier("customImageUseSample")
  }

  @ViewBuilder
  private var sourceStatus: some View {
    if store.isLoading {
      ProgressView(String(localized: "Preparing image…", bundle: .module))
    } else {
      Text(store.isUsingCustomImage
        ? String(localized: "Using your image", bundle: .module)
        : String(localized: "Using sample image", bundle: .module))
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("customImageSourceStatus")
    }
  }
}
