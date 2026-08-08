import CoreTransferable
import Foundation
import SortEngineKit
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  /// Declared as `UTExportedTypeDeclarations` in the app target's `Info.plist` (`Project.swift`),
  /// with file extension `.tape` — needed both for `ShareLink`'s export sheet to offer a sensible
  /// destination/filename and for `.fileImporter` to filter to exactly this kind of file.
  public static let tapeArchive = UTType(exportedAs: "com.nhubbard.Sort2.mobile.tapearchive", conformingTo: .data)
}

/// A `Transferable` wrapper around a `Tape`, so `ShareLink` has a real content type and a sensible
/// suggested filename to offer instead of generic `Data`. Wraps the `Tape` itself, not a
/// pre-computed `archived()` result: `DataRepresentation`'s `exporting` closure only runs when the
/// system actually needs the bytes for a real share action the user picked, not when this value is
/// constructed — constructing one (e.g. every `RunControlBar.body` evaluation) is therefore cheap
/// and does no encoding. Building this eagerly instead (as an earlier version did) forced a full
/// `tape.archived()` encode+hash+compress on the very first frame of every new sort, since `body`
/// re-evaluates on every playback tick.
public struct TapeArchiveDocument: Transferable {
  public let tape: Tape
  public let suggestedFileName: String

  public init(tape: Tape, suggestedFileName: String) {
    self.tape = tape
    self.suggestedFileName = suggestedFileName
  }

  public static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .tapeArchive) { document in
      try document.tape.archived()
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
/// is unreachable in practice. Wraps a `Tape` for the same lazy-encoding reason as
/// `TapeArchiveDocument` above — `fileWrapper(configuration:)` only runs once the user actually
/// confirms the save panel, not at button-render time.
public struct TapeExportFileDocument: FileDocument {
  public static var readableContentTypes: [UTType] { [.tapeArchive] }
  public static var writableContentTypes: [UTType] { [.tapeArchive] }

  public let tape: Tape

  public init(tape: Tape) {
    self.tape = tape
  }

  public init(configuration: ReadConfiguration) throws {
    throw CocoaError(.fileReadUnsupportedScheme)
  }

  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: try tape.archived())
  }
}
