import Combine
import Foundation
import UIKit

/// Reads the app's `Settings.bundle` choices from `UserDefaults` and republishes
/// them for SwiftUI.
///
/// The store uses an explicit **App Group** suite shared with `Settings.bundle`
/// (via its `ApplicationGroupContainerIdentifier`). This bypasses a dev-signing
/// quirk where Xcode `⌘R` reinstalls create a new per-install sandbox that
/// Settings.app's writes no longer reach.
///
/// Re-reads on every notification that could indicate the Settings.app or
/// another process may have written new values.
@MainActor
final class SettingsStore: ObservableObject {
    /// The App Group both `Settings.bundle` and the running app share.
    nonisolated static let appGroup = "group.neris.marrony.ColorWheel"

    @Published private(set) var wheel: WheelModel
    @Published private(set) var slices: SliceCount

    private let defaults: UserDefaults
    private var bag: Set<AnyCancellable> = []

    init(
        defaults: UserDefaults? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        // Prefer the App Group suite. Falls back to .standard if the App Groups
        // capability is missing from the target's entitlements.
        let resolved = defaults
            ?? UserDefaults(suiteName: Self.appGroup)
            ?? .standard
        self.defaults = resolved

        // Match the plist's DefaultValue so first-launch reads return the
        // expected values before the user has visited Settings.app.
        resolved.register(defaults: [
            SettingsKeys.wheelModel: WheelModel.artist.rawValue,
            SettingsKeys.sliceCount: SliceCount.off.rawValue,
        ])

        let initialWheel = resolved.string(forKey: SettingsKeys.wheelModel)
            .flatMap(WheelModel.init(rawValue:)) ?? .artist
        let initialSlices = SliceCount(rawValue: resolved.integer(forKey: SettingsKeys.sliceCount)) ?? .off
        self.wheel = initialWheel
        self.slices = initialSlices

        notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)
        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)
        notificationCenter.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)
    }

    func reload() {
        // synchronize() is officially deprecated but still nudges iOS to pull
        // the latest values from the on-disk plist for cross-process writes.
        defaults.synchronize()

        let newWheel = defaults.string(forKey: SettingsKeys.wheelModel)
            .flatMap(WheelModel.init(rawValue:)) ?? .artist
        let newSlices = SliceCount(rawValue: defaults.integer(forKey: SettingsKeys.sliceCount)) ?? .off
        if newWheel != wheel { wheel = newWheel }
        if newSlices != slices { slices = newSlices }
    }
}
