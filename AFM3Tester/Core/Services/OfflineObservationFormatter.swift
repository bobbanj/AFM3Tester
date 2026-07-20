import Foundation

/// Formats Offline Verification observation strings for Device Report / History exports.
enum OfflineObservationFormatter: Sendable {
    nonisolated static let suiteName = "Offline Verification"

    /// Device Report table value for offline-path observation.
    nonisolated static func deviceReportLabel(for run: DiagnosticRunRecord) -> String {
        guard let outcome = resolvedOutcome(for: run) else {
            return "Not Run"
        }

        var detailParts: [String] = []
        if let passed = run.offlineChecksPassed, let total = run.offlineChecksTotal, total > 0 {
            detailParts.append("\(passed)/\(total) checks")
        }
        if run.offlinePathObserved == true {
            detailParts.append("NWPathMonitor evidence")
        } else if run.offlinePathObserved == false {
            detailParts.append("path was satisfied")
        }

        if detailParts.isEmpty {
            return outcome.displayLabel
        }
        return "\(outcome.displayLabel) (\(detailParts.joined(separator: ", ")))"
    }

    nonisolated static func resolvedOutcome(for run: DiagnosticRunRecord) -> TestOutcome? {
        if let outcome = run.offlineOutcome {
            return outcome
        }
        return run.suiteResults.first(where: { $0.suiteName == suiteName })?.outcome
    }

    nonisolated static func checkCounts(from checks: [ValidationCheck]) -> (passed: Int, total: Int) {
        (checks.filter(\.passed).count, checks.count)
    }
}
