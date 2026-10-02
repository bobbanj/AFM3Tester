import Foundation

enum GitHubDeviceReportExporter: Sendable {

    nonisolated static func makeMarkdown(from run: DiagnosticRunRecord) -> String {
        var lines: [String] = []
        lines.append("## AFM3Tester Device Report")
        lines.append("")
        lines.append("_Beta-software observations from this device and build. Not a security certification._")
        lines.append("")
        lines.append("| Field | Value |")
        lines.append("| --- | --- |")
        lines.append("| AFM3Tester version | \(run.appVersion) (\(run.appBuild)) |")
        lines.append("| Device | \(run.marketingName) |")
        lines.append("| Hardware identifier | \(run.hardwareIdentifier) |")
        lines.append("| OS | \(run.osVersion) |")
        lines.append("| OS build | \(run.osBuild) |")
        lines.append("| Language | \(run.languageCode) |")
        lines.append("| Locale | \(run.localeIdentifier) |")
        lines.append("| Region | \(run.regionCode) |")
        lines.append("| Model API | \(run.modelAPIIdentifier) |")
        lines.append("| Availability | \(run.availability) |")
        lines.append("| Deployment observation | \(run.deploymentObservation) |")
        lines.append("| Context size | \(run.contextSize.map(String.init) ?? "not exposed") |")
        lines.append("| Overall status | \(run.overallStatus.displayLabel) |")
        lines.append("| Offline-path observation | \(OfflineObservationFormatter.deviceReportLabel(for: run)) |")
        lines.append("| Simulator | \(run.isSimulator ? "yes" : "no") |")
        if let completed = run.offlineCompletedAt {
            lines.append("| Offline Verification completed | \(ISO8601DateFormatter().string(from: completed)) |")
        }
        lines.append("")

        lines.append("### Suite statuses")
        lines.append("")
        if run.suiteResults.isEmpty {
            lines.append("_No suite results._")
        } else {
            for suite in run.suiteResults.sorted(by: { $0.suiteName < $1.suiteName }) {
                let summary = suite.summary.map { " — \($0)" } ?? ""
                lines.append("- **\(suite.suiteName)**: \(suite.outcome.displayLabel)\(summary)")
            }
        }
        lines.append("")

        lines.append("### Benchmark summary")
        lines.append("")
        if let bench = run.benchmarkSummary, bench.sampleCount > 0 {
            lines.append("- Sample count: \(bench.sampleCount)")
            lines.append("- Median total latency: \(formatSeconds(bench.medianTotalLatencySeconds))")
            lines.append("- Min total latency: \(formatSeconds(bench.minTotalLatencySeconds))")
            lines.append("- Max total latency: \(formatSeconds(bench.maxTotalLatencySeconds))")
            lines.append("- Median time to first streamed content: \(formatSeconds(bench.medianTimeToFirstStreamedContentSeconds))")
            lines.append("- Min / max TTFS: \(formatSeconds(bench.minTimeToFirstStreamedContentSeconds)) / \(formatSeconds(bench.maxTimeToFirstStreamedContentSeconds))")
            lines.append("- Median characters/sec: \(formatDouble(bench.medianCharactersPerSecond))")
            if let est = bench.estimatedMedianTokensPerSecond {
                lines.append("- Estimated tokens/sec (approx. 4 chars/token): \(String(format: "%.1f", est)) — estimate only")
            }
            lines.append("- Thermal before → after: \(bench.thermalStateBefore ?? "n/a") → \(bench.thermalStateAfter ?? "n/a")")
            lines.append("- Battery before → after: \(formatBattery(bench.batteryPercentageBefore)) → \(formatBattery(bench.batteryPercentageAfter))")
            lines.append("- Charging: \(bench.isCharging.map { $0 ? "yes" : "no" } ?? "n/a")")
            lines.append("- Low Power Mode: \(bench.isLowPowerModeEnabled.map { $0 ? "on" : "off" } ?? "n/a")")
        } else {
            lines.append("_No benchmark samples in this run._")
        }
        lines.append("")

        lines.append("### Errors (redacted categories)")
        lines.append("")
        if run.errorSummaries.isEmpty {
            lines.append("_No unexpected errors recorded._")
        } else {
            for error in run.errorSummaries {
                lines.append("- \(error.testName): \(error.category.rawValue) — \(error.redactedDescription)")
            }
        }
        lines.append("")
        lines.append("### Expected policy events")
        lines.append("")
        if run.policyEventSummaries.isEmpty {
            lines.append("_No expected policy events recorded._")
        } else {
            for event in run.policyEventSummaries {
                lines.append("- \(event.testName): \(event.kind.rawValue) — \(event.redactedSummary)")
            }
        }
        lines.append("")
        lines.append("### AFM3 Score")
        lines.append("")
        let score = AFM3ScoreCalculator.resolve(run)
        if score.isComplete, let composite = score.composite {
            lines.append("- Composite: \(composite)")
            lines.append("- Suite: \(score.suiteIdentifier) (v\(score.suiteVersion))")
            for sub in score.subScores {
                lines.append("- \(sub.title): \(sub.value.map(String.init) ?? "n/a")")
            }
            lines.append("- \(AFM3ScoreSuite.honestyNote)")
            lines.append("- Not an official Apple score. Not statistically significant.")
        } else {
            lines.append("_AFM3 Score incomplete for \(score.suiteIdentifier)._")
        }
        lines.append("")
        lines.append("### Disclaimer")
        lines.append("")
        lines.append("This report excludes prompts, full model outputs, Apple IDs, Team IDs, emails, phone numbers, UDIDs, and credentials. Values are observations from beta software and may change.")

        let joined = lines.joined(separator: "\n")
        return ReportRedactor.redactFreeTextPreservingMetrics(joined)
    }

    private nonisolated static func formatSeconds(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.3fs", value)
    }

    private nonisolated static func formatDouble(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.1f", value)
    }

    private nonisolated static func formatBattery(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.0f%%", value)
    }
}
