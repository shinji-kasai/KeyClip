//
//  LaunchAtLoginService.swift
//  KeyClip
//

import ServiceManagement

/// Wraps `SMAppService.mainApp` — macOS 13+'s login-item API, replacing the
/// deprecated `SMLoginItemSetEnabled`/shared-file-list approach. Registers
/// KeyClip itself to launch at login directly, no separate embedded helper
/// app needed (unlike the old API), and works for a non-sandboxed,
/// ad-hoc-signed app like this one — registration is tied to the bundle
/// path/identifier, not to Developer ID signing or sandbox entitlements.
/// Defaults to enabled — see `AppDelegate.setupLaunchAtLogin`, which syncs
/// actual registration to the stored preference on every launch, so this
/// also self-heals if something outside the app (e.g. the user removing it
/// via System Settings → Login Items directly) drifts out of sync.
enum LaunchAtLoginService {
    static let enabledDefaultsKey = "launchAtLoginEnabled"

    static var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Best-effort: `SMAppService` can fail transiently (e.g. right after a
    /// fresh install, before Launch Services has fully caught up with the
    /// new bundle) — the Settings toggle still reflects the user's stored
    /// preference either way, and the next app launch's sync in
    /// `AppDelegate` retries.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Ignored — see doc comment above.
        }
    }
}
