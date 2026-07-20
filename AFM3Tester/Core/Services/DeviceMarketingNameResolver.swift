import Foundation

/// Deterministic, auditable hardware-identifier → marketing-name map.
/// Unknown identifiers never invent a name from screen size or performance.
enum DeviceMarketingNameResolver: Sendable {

    /// Small curated map of common Apple device identifiers.
    /// Keep alphabetical by identifier family for auditability.
    nonisolated static let marketingNamesByIdentifier: [String: String] = [
        // iPhone 15 family
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        // iPhone 16 family
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        // iPhone 17 / 18-era identifiers observed in beta tooling
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone 17 Air",
        // Simulators commonly report these
        "arm64": "iOS Simulator",
        "x86_64": "iOS Simulator",
        "i386": "iOS Simulator",
    ]

    nonisolated static func marketingName(forHardwareIdentifier identifier: String) -> String {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Unknown Apple device (unknown)"
        }
        if let name = marketingNamesByIdentifier[trimmed] {
            return name
        }
        return "Unknown Apple device (\(trimmed))"
    }

    nonisolated static func displayLabel(forHardwareIdentifier identifier: String) -> String {
        let marketing = marketingName(forHardwareIdentifier: identifier)
        return "\(marketing) (\(identifier))"
    }
}
