import Foundation
import FoundationModels

enum ReportExporter: Sendable {

    @MainActor
    static func buildReport(from store: DiagnosticStore) -> DiagnosticReport {
        let model = SystemLanguageModel.default
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.2"

        return DiagnosticReport(
            appVersion: appVersion,
            device: DeviceInfoProvider.captureSnapshot(),
            modelAvailability: model.availability.displayDescription,
            modelDescription: ModelMetadataFormatter.apiModelIdentifier,
            deploymentType: FoundationModelService.deployment,
            contextWindowSize: model.contextSize,
            contextWindowExposed: true,
            lastSuccessfulInference: store.lastSuccessfulInference,
            testResults: Array(store.testResults.values).sorted { $0.testName < $1.testName },
            benchmarkSamples: store.currentBenchmarkSamples.isEmpty ? store.benchmarks : store.currentBenchmarkSamples,
            errors: store.errorLog,
            policyEvents: store.policyEvents,
            offlineTestSucceeded: {
                switch store.testResults["Offline Verification"]?.outcome {
                case .passed, .partial: true
                default: false
                }
            }(),
            offlineEvidenceRecords: store.offlineEvidenceRecords,
            includePromptText: store.includePromptsInExport,
            promptContents: store.includePromptsInExport ? nil : nil
        )
    }

    @MainActor
    static func exportJSON(report: DiagnosticReport) -> Data {
        let redacted = report.includePromptText ? report : ReportRedactor.redactDiagnosticReport(report)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(redacted)
        } catch {
            return Data("""
            {"error":"Failed to encode report: \(error.localizedDescription)"}
            """.utf8)
        }
    }

    nonisolated static func exportMarkdown(report: DiagnosticReport) -> String {
        let redacted = report.includePromptText ? report : ReportRedactor.redactDiagnosticReport(report)
        var lines: [String] = []

        lines.append("# AFM3Tester Diagnostic Report")
        lines.append("")
        lines.append("Generated: \(iso8601(redacted.generatedAt))")
        lines.append("App Version: \(redacted.appVersion)")
        lines.append("")
        lines.append("## Device")
        lines.append("- OS: \(redacted.device.osVersion) (\(redacted.device.osBuild))")
        lines.append("- Marketing name: \(redacted.device.marketingName)")
        lines.append("- Hardware identifier: \(redacted.device.deviceModel)")
        lines.append("- Locale: \(redacted.device.localeIdentifier)")
        lines.append("- Language: \(redacted.device.languageCode)")
        lines.append("- Region: \(redacted.device.regionCode)")
        lines.append("- Simulator: \(redacted.device.isSimulator ? "yes" : "no")")
        lines.append("- Thermal: \(redacted.device.thermalState)")
        lines.append("- Battery: \(formatBattery(redacted.device.batteryLevel))")
        lines.append("- Low Power Mode: \(redacted.device.isLowPowerModeEnabled ? "on" : "off")")
        lines.append("- Charging: \(redacted.device.isCharging ? "yes" : "no")")
        lines.append("")
        lines.append("## Model")
        lines.append("- API identifier: \(redacted.modelDescription)")
        lines.append("- Deployment: \(redacted.deploymentType ?? "unknown")")
        lines.append("- Availability: \(redacted.modelAvailability)")
        if redacted.contextWindowExposed, let size = redacted.contextWindowSize {
            lines.append("- Context Size (public SDK contextSize property): \(size) tokens")
        } else {
            lines.append("- Context Size: Not exposed by public SDK property")
        }
        if let lastInference = redacted.lastSuccessfulInference {
            lines.append("- Last Successful Inference: \(iso8601(lastInference))")
        }
        lines.append("")
        lines.append("## Overall")
        let overall = OverallStatusAggregator.aggregate(redacted.testResults.map(\.outcome))
        lines.append("- Status: \(overall.displayLabel)")
        lines.append("- Summary: \(OverallStatusAggregator.conciseSummary(from: redacted.testResults.map(\.outcome)))")
        lines.append("")
        lines.append("## Test Results")
        if redacted.testResults.isEmpty {
            lines.append("_No test results recorded._")
        } else {
            for result in redacted.testResults {
                lines.append("### \(result.testName) — \(result.outcome.displayLabel)")
                if let message = result.message {
                    lines.append("- Summary: \(message)")
                }
                if let latency = result.latency, let total = latency.totalGenerationSeconds {
                    lines.append("- Total Latency: \(String(format: "%.3f", total))s")
                }
                if !result.validationChecks.isEmpty {
                    let passed = result.validationChecks.filter { $0.passed }.count
                    lines.append("- Checks: \(passed)/\(result.validationChecks.count) passed")
                    for check in result.validationChecks {
                        let mark = check.passed ? "PASS" : "FAIL"
                        lines.append("  - [\(mark)] \(check.name)\(check.detail.map { ": \($0)" } ?? "")")
                    }
                }
                if let rawError = result.rawError, !rawError.isEmpty {
                    lines.append("")
                    lines.append("```")
                    lines.append(rawError)
                    lines.append("```")
                }
                lines.append("")
            }
        }
        lines.append("## Benchmarks")
        lines.append("_Current benchmark samples from the latest run (historical samples may also exist in History)._")
        if redacted.benchmarkSamples.isEmpty {
            lines.append("_No benchmark samples recorded._")
        } else {
            for sample in redacted.benchmarkSamples {
                lines.append("- \(sample.testName) #\(sample.repetition): " +
                    "total=\(formatSeconds(sample.latency.totalGenerationSeconds)), " +
                    "first-token=\(formatSeconds(sample.latency.timeToFirstTokenSeconds)), " +
                    "thermal=\(sample.thermalState)")
            }
        }
        lines.append("")
        lines.append("## Errors")
        if redacted.errors.isEmpty {
            lines.append("_No unexpected errors logged._")
        } else {
            for error in redacted.errors {
                lines.append("### \(iso8601(error.timestamp)) — \(error.testName)")
                lines.append("- Category: \(error.category.rawValue)")
                lines.append("- Availability: \(error.availabilityState)")
                lines.append("- Description: \(error.localizedDescription)")
                lines.append("- Debug: \(error.debugDescription)")
                if let nested = error.nestedDetails {
                    lines.append("- Nested: \(nested)")
                }
                lines.append("")
            }
        }
        lines.append("## Expected Policy Events")
        lines.append("_Informational. These are intentional application policy denials, not runtime failures._")
        if redacted.policyEvents.isEmpty {
            lines.append("_No expected policy events recorded._")
        } else {
            for event in redacted.policyEvents {
                lines.append("- \(iso8601(event.timestamp)) — \(event.testName): \(event.kind.rawValue) — \(event.summary)")
            }
        }
        lines.append("")
        lines.append("## Offline Verification")
        lines.append("_NWPathMonitor reports path status only; it cannot prove every radio is disabled._")
        if let offlineResult = redacted.testResults.first(where: { $0.testName == OfflineObservationFormatter.suiteName }) {
            let counts = OfflineObservationFormatter.checkCounts(from: offlineResult.validationChecks)
            lines.append("- Outcome: \(offlineResult.outcome.displayLabel)")
            if counts.total > 0 {
                lines.append("- Checks: \(counts.passed)/\(counts.total) passed")
            }
            if let message = offlineResult.message {
                lines.append("- Summary: \(message)")
            }
        } else if let evidence = redacted.offlineEvidenceRecords.last {
            let counts = OfflineObservationFormatter.checkCounts(from: evidence.checks)
            lines.append("- Outcome: \(evidence.testOutcome.displayLabel)")
            if counts.total > 0 {
                lines.append("- Checks: \(counts.passed)/\(counts.total) passed")
            }
            lines.append("- Completed: \(iso8601(evidence.completedAt))")
        } else if let offline = redacted.offlineTestSucceeded {
            lines.append("- Inference while no satisfied path observed: \(offline ? "yes" : "no")")
        } else {
            lines.append("- Offline-path observation: Not Run")
        }
        if redacted.offlineEvidenceRecords.isEmpty {
            lines.append("_No offline evidence records exported._")
        } else {
            lines.append("")
            lines.append("### Offline evidence records")
            for record in redacted.offlineEvidenceRecords {
                lines.append("- Started: \(iso8601(record.startedAt))")
                lines.append("  Completed: \(iso8601(record.completedAt))")
                lines.append("  Path status: \(record.networkPathStatus)")
                lines.append("  Path satisfied: \(record.pathSatisfied ? "yes" : "no")")
                lines.append("  Interfaces: \(record.availableInterfaces.joined(separator: ", "))")
                lines.append("  Outcome: \(record.testOutcome.displayLabel)")
                if let message = record.message {
                    lines.append("  Summary: \(message)")
                }
            }
        }

        if !redacted.includePromptText {
            lines.append("")
            lines.append("_Prompt text excluded from export. Enable \"Include prompt text in export\" to include._")
        }

        return lines.joined(separator: "\n")
    }

    @MainActor
    static func exportJSON(from store: DiagnosticStore) -> Data {
        exportJSON(report: buildReport(from: store))
    }

    // MARK: - Formatting

    nonisolated private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    nonisolated private static func formatBattery(_ level: Double?) -> String {
        guard let level else { return "n/a" }
        return String(format: "%.0f%%", level * 100)
    }

    nonisolated private static func formatSeconds(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.3fs", value)
    }
}
