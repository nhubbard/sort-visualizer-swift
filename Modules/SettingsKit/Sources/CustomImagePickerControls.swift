import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// The same image choice controls appear beside the live visualizer picker and in Settings.
public struct CustomImagePickerControls: View {
  @State private var store = CustomImageStore.shared
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var isFileImporterPresented = false

  public init() {}

  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
          Label("Choose Photo", systemImage: "photo.on.rectangle")
        }
        .accessibilityIdentifier("customImageChoosePhoto")

        Button {
          isFileImporterPresented = true
        } label: {
          Label("Choose File", systemImage: "folder")
        }
        .accessibilityIdentifier("customImageChooseFile")

        if store.isUsingCustomImage {
          Button("Use Sample Image") { store.useSampleImage() }
            .accessibilityIdentifier("customImageUseSample")
        }
      }
      .buttonStyle(.bordered)

      if store.isLoading {
        ProgressView("Preparing image…")
      } else {
        Text(store.isUsingCustomImage ? "Using your image" : "Using sample image")
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("customImageSourceStatus")
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
}
