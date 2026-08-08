import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  /// Declared as `UTExportedTypeDeclarations` in the app target's `Info.plist` (`Project.swift`),
  /// with file extension `.tape` — needed both for `ShareLink`'s export sheet to offer a sensible
  /// destination/filename and for `.fileImporter` to filter to exactly this kind of file.
  public static let tapeArchive = UTType(exportedAs: "com.nhubbard.Sort2.mobile.tapearchive", conformingTo: .data)
}

/// A `Transferable` wrapper around one `Tape.archived()` result, so `ShareLink` has a real content
/// type and a sensible suggested filename to offer instead of generic `Data`.
public struct TapeArchiveDocument: Transferable {
  public let data: Data
  public let suggestedFileName: String

  public init(data: Data, suggestedFileName: String) {
    self.data = data
    self.suggestedFileName = suggestedFileName
  }

  public static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .tapeArchive) { document in
      document.data
    }
    .suggestedFileName { document in
      document.suggestedFileName
    }
  }
}

/// Backs Mac Catalyst's `.fileExporter` (→ a native `NSSavePanel`) — Catalyst's `ShareLink` maps
/// to `NSSharingServicePicker`, which needs a real file-backed promise to match any built-in
/// service (Mail, AirDrop, "Send File To…") and shows nothing but "Edit Extensions…" for a pure
/// in-memory `Transferable` like `TapeArchiveDocument`. `.fileExporter` is the idiomatic
/// direct-to-disk path there instead. Write-only: never read back in, so `init(configuration:)`
/// is unreachable in practice.
public struct TapeExportFileDocument: FileDocument {
  public static var readableContentTypes: [UTType] { [.tapeArchive] }
  public static var writableContentTypes: [UTType] { [.tapeArchive] }

  public let data: Data

  public init(data: Data) {
    self.data = data
  }

  public init(configuration: ReadConfiguration) throws {
    throw CocoaError(.fileReadUnsupportedScheme)
  }

  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
