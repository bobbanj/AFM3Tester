import Foundation

enum ReportRedactor: Sendable {

    nonisolated private static let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    nonisolated private static let phonePattern = #"(?:\+?\d{1,3}[\s.-]?)?(?:\(?\d{2,4}\)?[\s.-]?)?\d{3}[\s.-]?\d{4,}"#
    nonisolated private static let apiKeyPatterns: [String] = [
        #"(?i)(api[_-]?key|apikey|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{12,}['"]?"#,
        #"\bsk-[A-Za-z0-9]{20,}\b"#,
        #"\bBearer\s+[A-Za-z0-9_\-\.]{12,}\b"#,
        #"(?i)(password|passwd|pwd)\s*[:=]\s*['"]?[^\s'"]{6,}['"]?"#,
    ]

    nonisolated static func redact(_ text: String) -> String {
        var result = text
        result = replaceMatches(in: result, pattern: emailPattern, replacement: "[REDACTED_EMAIL]")
        result = replaceMatches(in: result, pattern: phonePattern, replacement: "[REDACTED_PHONE]")
        for pattern in apiKeyPatterns {
            result = replaceMatches(in: result, pattern: pattern, replacement: "[REDACTED_SECRET]")
        }
        return result
    }

    nonisolated static func redactDiagnosticReport(_ report: DiagnosticReport) -> DiagnosticReport {
        DiagnosticReport(
            generatedAt: report.generatedAt,
            appVersion: report.appVersion,
            device: report.device,
            modelAvailability: report.modelAvailability,
            modelDescription: report.modelDescription,
            deploymentType: report.deploymentType,
            contextWindowSize: report.contextWindowSize,
            contextWindowExposed: report.contextWindowExposed,
            lastSuccessfulInference: report.lastSuccessfulInference,
            testResults: report.testResults.map(redactTestResult),
            benchmarkSamples: report.benchmarkSamples,
            errors: report.errors.map(redactErrorEntry),
            offlineTestSucceeded: report.offlineTestSucceeded,
            offlineEvidenceRecords: report.offlineEvidenceRecords,
            includePromptText: false,
            promptContents: nil
        )
    }

    nonisolated private static func redactTestResult(_ result: TestResult) -> TestResult {
        TestResult(
            id: result.id,
            testName: result.testName,
            category: result.category,
            outcome: result.outcome,
            message: result.message.map(redact),
            latency: result.latency,
            validationChecks: result.validationChecks.map { check in
                ValidationCheck(
                    id: check.id,
                    name: check.name,
                    passed: check.passed,
                    detail: check.detail.map(redact)
                )
            },
            manualRating: result.manualRating,
            rawError: result.rawError.map(redact),
            recordedAt: result.recordedAt
        )
    }

    nonisolated private static func redactErrorEntry(_ entry: ErrorLogEntry) -> ErrorLogEntry {
        ErrorLogEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            testName: entry.testName,
            availabilityState: entry.availabilityState,
            localizedDescription: redact(entry.localizedDescription),
            debugDescription: redact(entry.debugDescription),
            category: entry.category,
            nestedDetails: entry.nestedDetails.map(redact)
        )
    }

    nonisolated private static func replaceMatches(
        in text: String,
        pattern: String,
        replacement: String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}
