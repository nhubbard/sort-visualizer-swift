import Foundation

public typealias StringRange = Range<String.Index>

extension Sequence where Iterator.Element : Hashable {
  var indexHash: Dictionary<Iterator.Element, Int> {
    get {
      var result = [Iterator.Element: Int]()
      var index = 0
      for e in self {
        result[e] = index
        index += 1
      }
      return result
    }
  }
}
