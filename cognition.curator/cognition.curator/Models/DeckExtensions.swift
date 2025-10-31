import Foundation

enum DeckSilenceType: String, CaseIterable {
    case permanent = "permanent"
    case temporary = "temporary"

    var displayName: String {
        switch self {
        case .permanent:
            return "Permanent"
        case .temporary:
            return "Temporary"
        }
    }
}

extension Deck {

    // MARK: - Silence Status

    var isCurrentlySilenced: Bool {
        guard isSilenced else { return false }

        // If it's permanent silence, it's always silenced
        if silenceType == DeckSilenceType.permanent.rawValue {
            return true
        }

        // For temporary silence, check if we're still within the silence period
        if silenceType == DeckSilenceType.temporary.rawValue,
           let endDate = silenceEndDate {
            return Date() < endDate
        }

        // Default to not silenced if something is wrong
        return false
    }

    var silenceTypeEnum: DeckSilenceType? {
        guard let silenceType = silenceType else { return nil }
        return DeckSilenceType(rawValue: silenceType)
    }

    var silenceDescription: String {
        guard isCurrentlySilenced else { return "Not silenced" }

        if silenceType == DeckSilenceType.permanent.rawValue {
            return "Silenced permanently"
        } else if silenceType == DeckSilenceType.temporary.rawValue,
                  let endDate = silenceEndDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Silenced until \(formatter.localizedString(for: endDate, relativeTo: Date()))"
        }

        return "Silenced"
    }

    // MARK: - Silence Actions

    func silencePermanently() {
        self.isSilenced = true
        self.silenceType = DeckSilenceType.permanent.rawValue
        self.silenceEndDate = nil
        self.updatedAt = Date()
    }

    func silenceTemporarily(until endDate: Date) {
        self.isSilenced = true
        self.silenceType = DeckSilenceType.temporary.rawValue
        self.silenceEndDate = endDate
        self.updatedAt = Date()
    }

    func unsilence() {
        self.isSilenced = false
        self.silenceType = nil
        self.silenceEndDate = nil
        self.updatedAt = Date()
    }

    // MARK: - Automatic Silence Expiry

    func checkAndUpdateSilenceExpiry() {
        guard isSilenced,
              silenceType == DeckSilenceType.temporary.rawValue,
              let endDate = silenceEndDate,
              Date() >= endDate else { return }

        // Temporary silence has expired, unsilence the deck
        unsilence()
    }
}
