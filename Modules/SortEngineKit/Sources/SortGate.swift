import Foundation

/// Replaces the bespoke `showBogoSortWarning`/`bogoSortAccepted`/`showBitonicWarning` boolean-pair
/// dance. `AlgorithmMetadata.confirmationWarning` drives this directly — a new algorithm that
/// deserves a warning just sets that one metadata field, no new flags, no new handler functions.
public struct AlgorithmWarning: Equatable, Sendable {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource

    public init(title: LocalizedStringResource, message: LocalizedStringResource) {
        self.title = title
        self.message = message
    }
}

public enum SortGate: Equatable, Sendable {
    case clear
    case needsConfirmation(AlgorithmWarning)
    case declined
}
