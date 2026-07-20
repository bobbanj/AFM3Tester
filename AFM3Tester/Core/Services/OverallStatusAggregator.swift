import Foundation

/// Deterministic overall-status rules for multi-suite diagnostic runs.
///
/// Rules (applied in order):
/// 1. Empty outcome list → `.skipped`
/// 2. Any `.failed` → `.failed`
/// 3. All meaningful outcomes `.unavailable` → `.unavailable`
/// 4. Mixed `.unavailable` with other meaningful results → `.failed`
/// 5. Any `.partial` → `.partial`
/// 6. Any `.passed` → `.passed`
/// 7. Else any `.expectedPolicyBlock` → `.expectedPolicyBlock`
/// 8. Else only skips/observations → `.skipped`
enum OverallStatusAggregator: Sendable {

    nonisolated static func aggregate(_ outcomes: [TestOutcome]) -> OverallRunStatus {
        guard !outcomes.isEmpty else { return .skipped }

        if outcomes.contains(.failed) {
            return .failed
        }

        let meaningful = outcomes.filter { outcome in
            switch outcome {
            case .skipped, .observation:
                false
            case .passed, .expectedPolicyBlock, .partial, .failed, .unavailable:
                true
            }
        }

        if meaningful.isEmpty {
            return .skipped
        }

        if meaningful.allSatisfy({ $0 == .unavailable }) {
            return .unavailable
        }

        if meaningful.contains(.unavailable) {
            return .failed
        }

        if meaningful.contains(.partial) {
            return .partial
        }

        if meaningful.contains(.passed) {
            return .passed
        }

        if meaningful.contains(.expectedPolicyBlock) {
            return .expectedPolicyBlock
        }

        return .skipped
    }

    nonisolated static func summaryCounts(from outcomes: [TestOutcome]) -> [TestOutcome: Int] {
        var counts: [TestOutcome: Int] = [:]
        for outcome in outcomes {
            counts[outcome, default: 0] += 1
        }
        return counts
    }

    nonisolated static func conciseSummary(from outcomes: [TestOutcome]) -> String {
        let overall = aggregate(outcomes)
        let counts = summaryCounts(from: outcomes)
        let parts = [
            "\(counts[.passed, default: 0]) passed",
            "\(counts[.partial, default: 0]) partial",
            "\(counts[.expectedPolicyBlock, default: 0]) expected policy",
            "\(counts[.failed, default: 0]) failed",
            "\(counts[.unavailable, default: 0]) unavailable",
            "\(counts[.skipped, default: 0]) skipped",
        ]
        return "\(overall.displayLabel) — \(parts.joined(separator: ", "))"
    }

    /// Suite-level status from validation checks (e.g. offline verification).
    nonisolated static func suiteOutcome(fromChecks checks: [ValidationCheck], requiredAllPass: Bool = false) -> TestOutcome {
        guard !checks.isEmpty else { return .skipped }
        let passed = checks.filter { $0.passed }.count
        if passed == checks.count { return .passed }
        if requiredAllPass { return .failed }
        if passed > 0 { return .partial }
        return .failed
    }
}
