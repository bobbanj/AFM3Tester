import XCTest
@testable import AFM3Tester

@MainActor
final class GitHubDeviceReportExporterTests: XCTestCase {
    func testReportRedactsSecretsAndOmitsPrompts() {
        let run = DiagnosticRunRecord(
            appVersion: "0.2.0",
            appBuild: "2",
            osVersion: "27.0",
            osBuild: "24A000",
            hardwareIdentifier: "iPhone18,2",
            marketingName: "iPhone 17 Pro Max",
            localeIdentifier: "en_US",
            languageCode: "en",
            regionCode: "SE",
            modelAPIIdentifier: "SystemLanguageModel.default",
            availability: "Available",
            deploymentObservation: "On-Device (SystemLanguageModel)",
            contextSize: 8192,
            overallStatus: .expectedPolicyBlock,
            overallSummary: "Expected policy block",
            suiteResults: [
                StoredSuiteResult(
                    suiteName: "Tool Calling",
                    category: "tools",
                    outcome: .expectedPolicyBlock,
                    summary: "Contact user@example.com leaked api_key=sk-abcdefghijklmnopqrstuvwxyz123456",
                    totalLatencySeconds: 1.2,
                    timeToFirstStreamedContentSeconds: 0.3,
                    errorCategory: nil
                )
            ],
            benchmarkSummary: BenchmarkSummary(
                sampleCount: 3,
                medianTotalLatencySeconds: 1.0,
                minTotalLatencySeconds: 0.8,
                maxTotalLatencySeconds: 1.4,
                medianTimeToFirstStreamedContentSeconds: 0.2,
                minTimeToFirstStreamedContentSeconds: 0.1,
                maxTimeToFirstStreamedContentSeconds: 0.3,
                medianCharactersPerSecond: 40,
                estimatedMedianTokensPerSecond: 10,
                thermalStateBefore: "nominal",
                thermalStateAfter: "nominal",
                batteryPercentageBefore: 70,
                batteryPercentageAfter: 69,
                isCharging: true,
                isLowPowerModeEnabled: false
            ),
            thermalState: "nominal",
            batteryPercentage: 70,
            isCharging: true,
            isLowPowerModeEnabled: false,
            offlinePathObserved: true,
            offlineOutcome: .passed,
            offlineChecksPassed: 4,
            offlineChecksTotal: 4,
            offlineCompletedAt: Date(timeIntervalSince1970: 1_700_000_000),
            errorSummaries: [
                StoredErrorSummary(
                    id: UUID(),
                    testName: "Tool Calling",
                    category: .toolCallFailure,
                    redactedDescription: "Call +1 555-123-4567"
                )
            ],
            policyEventSummaries: [
                StoredPolicyEventSummary(
                    id: UUID(),
                    testName: "Tool Calling",
                    kind: .sideEffectsNotAllowed,
                    redactedSummary: "Side-effect correctly denied without explicit permission"
                )
            ],
            isSimulator: false
        )

        let markdown = GitHubDeviceReportExporter.makeMarkdown(from: run)
        XCTAssertTrue(markdown.contains("AFM3Tester Device Report"))
        XCTAssertTrue(markdown.contains("iPhone 17 Pro Max"))
        XCTAssertTrue(markdown.contains("iPhone18,2"))
        XCTAssertTrue(markdown.contains("Expected policy block") || markdown.contains("Expected policy events"))
        XCTAssertTrue(markdown.contains("Passed (4/4 checks, NWPathMonitor evidence)"))
        XCTAssertTrue(markdown.contains("Offline Verification completed"))
        XCTAssertFalse(markdown.lowercased().contains("not run"))
        XCTAssertTrue(markdown.contains("sideEffectsNotAllowed"))
        XCTAssertFalse(markdown.contains("user@example.com"))
        XCTAssertFalse(markdown.contains("sk-abcdefghijklmnopqrstuvwxyz123456"))
        XCTAssertFalse(markdown.contains("555-123-4567"))
        XCTAssertFalse(markdown.lowercased().contains("prompt:"))
        XCTAssertTrue(markdown.contains("estimate only") || markdown.contains("Estimated tokens/sec"))
        XCTAssertFalse(markdown.contains("555-123-4567"))
        XCTAssertTrue(markdown.contains("[REDACTED_PHONE]"), "Phone numbers in free-text error summaries should still redact")
        XCTAssertTrue(markdown.contains("1.0") || markdown.contains("0.8"), "Benchmark latency numbers must remain unredacted")
    }
}
