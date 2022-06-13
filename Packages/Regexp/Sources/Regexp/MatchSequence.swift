import Foundation

/// Match sequence is a sequence given as a result of findAll operation.
public class MatchSequence: Sequence {
  let source: String
  let context: CompiledMatchContext
  let groupNames: [String]
  
  init(source: String, context: CompiledMatchContext, groupNames: [String]) {
    self.source = source
    self.context = context
    self.groupNames = groupNames
  }
  
  public typealias Iterator = AnyIterator<Match>
  
  /// Method is required by the Sequence protocol
  public func makeIterator() -> Iterator {
    var index = context.startIndex
    return Iterator {
      if self.context.endIndex > index {
        let result = Match(source: self.source, match: self.context[index], groupNames: self.groupNames)
        index = index.advanced(by: 1)
        return result
      } else {
        return nil
      }
    }
  }
}
