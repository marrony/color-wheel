import Foundation

/// UserDefaults keys exposed in `Settings.bundle/Root.plist`.
///
/// Kept in this file so the Swift and plist sides stay in sync. If you
/// rename a key here, also rename it in the plist (and vice versa).
enum SettingsKeys {
    static let wheelModel = "wheel_model"   // String: "artist" | "digital"
    static let sliceCount = "slice_count"   // Int: 0 | 6 | 12 | 24
    static let savedState = "saved_state"   // Data: JSON-encoded SavedState
}
