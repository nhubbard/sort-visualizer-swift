import SortEngineKit

/// Keeps an algorithm's explanation next to the comparison that makes its decision.
/// These wrappers retain the underlying comparison and its recording semantics.
extension RecordingEngine {
  @discardableResult
  mutating func teachingCompare(
    _ first: Int, _ second: Int, by predicate: (Int, Int) -> Bool = (>=),
    stageID: String, whenTrue: String, whenFalse: String
  ) -> Bool {
    let result = compare(first, second, by: predicate)
    guard shouldAnnotateCurrentOperation else { return result }
    annotateLastOperation(
      stageID: stageID, decisionID: stageID, outcome: result ? "true" : "false",
      roles: ["first": .arrayIndex(first), "second": .arrayIndex(second)],
      explanationKey: stageID, explanation: result ? whenTrue : whenFalse)
    return result
  }

  @discardableResult
  mutating func teachingCompareValue(
    _ index: Int, against value: Int, by predicate: (Int, Int) -> Bool = (>=),
    stageID: String, whenTrue: String, whenFalse: String
  ) -> Bool {
    let result = compareValue(index, against: value, by: predicate)
    guard shouldAnnotateCurrentOperation else { return result }
    annotateLastOperation(
      stageID: stageID, decisionID: stageID, outcome: result ? "true" : "false",
      roles: ["candidate": .arrayIndex(index), "heldValue": .value(value)],
      explanationKey: stageID, explanation: result ? whenTrue : whenFalse)
    return result
  }

  @discardableResult
  mutating func teachingCompareValues(
    _ first: Int, _ second: Int, by predicate: (Int, Int) -> Bool = (>=),
    stageID: String, whenTrue: String, whenFalse: String
  ) -> Bool {
    let result = compareValues(first, second, by: predicate)
    guard shouldAnnotateCurrentOperation else { return result }
    annotateLastOperation(
      stageID: stageID, decisionID: stageID, outcome: result ? "true" : "false",
      roles: ["first": .value(first), "second": .value(second)],
      explanationKey: stageID, explanation: result ? whenTrue : whenFalse)
    return result
  }
}
