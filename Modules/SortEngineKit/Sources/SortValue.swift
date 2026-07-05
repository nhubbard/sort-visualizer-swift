import Foundation

/// Pure model, no `Color`, no `CGFloat` — the array of values a user edits before a sort starts.
/// Presentation state (markers, sorted-ness) only exists once replay begins, in `ReplayEngine.BarState`.
public struct SortValue: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var value: Int

    public init(id: UUID = UUID(), value: Int) {
        self.id = id
        self.value = value
    }
}
