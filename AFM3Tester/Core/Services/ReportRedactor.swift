import Foundation

enum ReportRedactor: Sendable {

    nonisolated private static let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
    /// Require phone-like separators or a leading +. Avoids matching decimal latency/metrics.
    nonisolated private static let phonePattern = #"(?:\+\d{1,3}[\s.-]+)?(?:\(\d{2,4}\)[\s.-]*|\d{2,4}[\s.-]+)\d{3}[\s.-]+\d{4}"#
    nonisolated private static let apiKeyPatterns: [String] = [
        #"(?i)(api[_-]?key|apikey|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{12,}['"]?"#,
        #"\bsk-[A-Za-z0-9]{20,}\b"#,
        #"\bBearer\s+[A-Za-z0-9_\-\.]{12,}\b"#,
        #"(?i)(password|passwd|pwd)\s*[:=]\s*['"]?[^\s'"]{6,}['"]?"#,
    ]

    /// Redacts free-text only. Numeric metrics, versions, builds, and hardware IDs are preserved.
    nonisolated static func redact(_ text: String) -> String {
        var result = text
        result = replaceMatches(in: result, pattern: emailPattern, replacement: "[REDACTED_EMAIL]")
        result = replaceMatches(in: result, pattern: phonePattern, replacement: "[REDACTED_PHONE]")
        for pattern in apiKeyPatterns {
            result = replaceMatches(in: result, pattern: pattern, replacement: "[REDACTED_SECRET]")
        }
        return result
    }

    /// Redacts free-text fields on a report without touching structured numeric metadata.
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
            policyEvents: report.policyEvents.map(redactPolicyEvent),
            offlineTestSucceeded: report.offlineTestSucceeded,
            offlineEvidenceRecords: report.offlineEvidenceRecords,
            includePromptText: report.includePromptText,
            promptContents: report.promptContents?.map(redact)
        )
    }

    nonisolated private static func redactTestResult(_ result: TestResult) -> TestResult {
        TestResult(
            id: result.id,
            testName: result.testName,
            category: result.category,
            outcome: result.outcome,
            message: result.message.map(redactFreeTextPreservingMetrics),
            latency: result.latency,
            validationChecks: result.validationChecks.map { check in
                ValidationCheck(
                    id: check.id,
                    name: check.name,
                    passed: check.passed,
                    detail: check.detail.map(redactFreeTextPreservingMetrics)
                )
            },
            manualRating: result.manualRating,
            rawError: result.rawError.map(redactFreeTextPreservingMetrics),
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

    nonisolated private static func redactPolicyEvent(_ entry: PolicyEventEntry) -> PolicyEventEntry {
        PolicyEventEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            testName: entry.testName,
            kind: entry.kind,
            summary: redact(entry.summary),
            detail: entry.detail.map(redact)
        )
    }

    /// Preserves latency/benchmark/token/version-like spans while redacting emails/phones/secrets.
    nonisolated static func redactFreeTextPreservingMetrics(_ text: String) -> String {
        // Temporarily shield metric-like tokens from phone matching.
        let shields = shieldMetricSpans(in: text)
        let redacted = redact(shields.shielded)
        return unshield(redacted, tokens: shields.tokens)
    }

    private struct ShieldResult {
        let shielded: String
        let tokens: [String]
    }

    nonisolated private static func shieldMetricSpans(in text: String) -> ShieldResult {
        let patterns = [
            #"(?i)\bLatency:\s*[0-9]+(?:\.[0-9]+)?s?\b"#,
            #"\b[0-9]+\.[0-9]+s\b"#,
            #"\b[0-9]+(?:\.[0-9]+)?%"#,
            #"\biPhone\d+,\d+\b"#,
            #"\b\d+\.\d+\.\d+\b"#,
            #"(?i)\b(total|median|min|max|ttfs|tokens?/sec|chars?/sec)[=:\s]+[0-9]+(?:\.[0-9]+)?"#,
        ]
        var tokens: [String] = []
        var result = text
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let token = "«METRIC\(tokens.count)»"
                tokens.append(String(result[range]))
                result.replaceSubrange(range, with: token)
            }
        }
        return ShieldResult(shielded: result, tokens: tokens)
    }

    nonisolated private static func unshield(_ text: String, tokens: [String]) -> String {
        var result = text
        for (index, value) in tokens.enumerated() {
            result = result.replacingOccurrences(of: "«METRIC\(index)»", with: value)
        }
        return result
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
