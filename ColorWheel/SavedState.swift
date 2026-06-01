import Foundation

/// The full bundle of user state we persist across app restarts.
///
/// Whenever this struct changes, JSON decoding must remain tolerant of
/// previously-saved blobs — either make new fields optional, or provide
/// default values via a custom `init(from:)`. With every field optional,
/// Swift's synthesized `Codable` already handles missing keys.
struct SavedState: Equatable, Codable {
    /// The most-recently captured / edited color.
    var sample: HSB?

    // MARK: - Persistence

    /// Where the blob lives. Uses the App Group suite shared with
    /// `Settings.bundle` / `SettingsStore` so it survives Xcode `⌘R`
    /// reinstalls under a Personal Team (the per-install sandbox container
    /// reshuffles, but the App Group container does not).
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SettingsStore.appGroup) ?? .standard
    }

    /// Load the saved state, or an empty `SavedState()` if nothing has
    /// been written yet (or the stored blob fails to decode).
    static func load() -> SavedState {
        guard let data = defaults.data(forKey: SettingsKeys.savedState),
              let decoded = try? JSONDecoder().decode(SavedState.self, from: data)
        else { return SavedState() }
        return decoded
    }

    /// Persist the current value.
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: SettingsKeys.savedState)
    }
}
