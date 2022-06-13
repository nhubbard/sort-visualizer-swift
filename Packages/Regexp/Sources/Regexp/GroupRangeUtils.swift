import Foundation

enum InvalidRangeError: Error {
  case Error
}

extension GroupRange {
  func asRange(ofString source: String) throws -> StringRange {
    let len = source.utf16.count
    if self.location < 0 || self.location >= len || self.location + self.length > len {
      throw InvalidRangeError.Error
    }
    let start = source.utf16.index(source.startIndex, offsetBy: self.location)
    let end = source.utf16.index(start, offsetBy: self.length)
    return start..<end
  }
}
