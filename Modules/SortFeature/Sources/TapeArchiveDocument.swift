import CoreTransferable
import Foundation
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
