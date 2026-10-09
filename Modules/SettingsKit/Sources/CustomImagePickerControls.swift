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
        LabeledContent("Source") { sourceStatus }
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
    .alert("Image Unavailable", isPresented: Binding(
      get: { store.errorMessage != nil },
      set: { if !$0 { store.errorMessage = nil } }
    )) {
      Button("OK") { store.errorMessage = nil }
    } message: {
      Text(store.errorMessage ?? "Choose another image.")
    }
  }

  private var photoButton: some View {
    PhotosPicker(selection: $selectedPhoto, matching: .images) {
      Label("Choose Photo", systemImage: "photo.on.rectangle")
    }
    .accessibilityIdentifier("customImageChoosePhoto")
  }

  private var fileButton: some View {
    Button {
      isFileImporterPresented = true
    } label: {
      Label("Choose File", systemImage: "folder")
    }
    .accessibilityIdentifier("customImageChooseFile")
  }

  private var sampleButton: some View {
    Button("Use Sample Image") { store.useSampleImage() }
      .accessibilityIdentifier("customImageUseSample")
  }

  @ViewBuilder
  private var sourceStatus: some View {
    if store.isLoading {
      ProgressView("Preparing image…")
    } else {
      Text(store.isUsingCustomImage ? "Using your image" : "Using sample image")
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("customImageSourceStatus")
    }
  }
}
