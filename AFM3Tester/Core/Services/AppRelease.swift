import Foundation

/// Marketing version and build fallbacks used when the bundle Info.plist is unavailable (tests, previews).
enum AppRelease: Sendable {
    nonisolated static let marketingVersionFallback = "0.3.0"
    nonisolated static let buildNumberFallback = "5"

    nonisolated static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? marketingVersionFallback
    }

    nonisolated static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? buildNumberFallback
    }
}
