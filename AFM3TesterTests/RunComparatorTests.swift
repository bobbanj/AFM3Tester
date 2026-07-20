import XCTest
@testable import AFM3Tester

@MainActor
final class RunComparatorTests: XCTestCase {
    func testPercentChangeRejectsDivideByZero() {
        let (pct, valid) = RunComparator.percentChange(from: 0, to: 5)
        XCTAssertNil(pct)
        XCTAssertFalse(valid)
    }

    func testPercentChangeValidWhenBaselineNonZero() {
        let (pct, valid) = RunComparator.percentChange(from: 2, to: 3)
        XCTAssertEqual(pct!, 50.0, accuracy: 0.001)
        XCTAssertTrue(valid)
    }

    func testCrossDeviceWarningPresent() {
        let left = makeRun(id: UUID(), hardware: "iPhone18,2", suiteFailed: false)
        let right = makeRun(id: UUID(), hardware: "iPhone17,1", suiteFailed: true)
        let result = RunComparator.compare(left: left, right: right)
        XCTAssertNotNil(result.crossDeviceWarning)
        XCTAssertTrue(result.deviceChanged)
        XCTAssertEqual(result.addedFailures, ["Tool Calling"])
        XCTAssertTrue(result.metricDeltas.contains { !$0.percentChangeValid && $0.left != nil && $0.right != nil && ($0.left ?? 0) != 0 })
    }

    func testResolvedFailuresDetected() {
        let left = makeRun(id: UUID(), hardware: "iPhone18,2", suiteFailed: true)
        let right = makeRun(id: UUID(), hardware: "iPhone18,2", suiteFailed: false)
        let result = RunComparator.compare(left: left, right: right)
        XCTAssertEqual(result.resolvedFailures, ["Tool Calling"])
        XCTAssertNil(result.crossDeviceWarning)
    }

    private func makeRun(id: UUID, hardware: String, suiteFailed: Bool) -> DiagnosticRunRecord {
        DiagnosticRunRecord(
            id: id,
            appVersion: "0.2.0",
            appBuild: "2",
            osVersion: "27.0",
            osBuild: "24A000",
            hardwareIdentifier: hardware,
            marketingName: DeviceMarketingNameResolver.marketingName(forHardwareIdentifier: hardware),
            localeIdentifier: "en_US",
            languageCode: "en",
            regionCode: "US",
            modelAPIIdentifier: "SystemLanguageModel.default",
            availability: "Available",
            deploymentObservation: "On-Device",
            contextSize: 8192,
            overallStatus: suiteFailed ? .failed : .passed,
            overallSummary: "test",
            suiteResults: [
                StoredSuiteResult(
                    suiteName: "Tool Calling",
                    category: "tools",
                    outcome: suiteFailed ? .failed : .expectedPolicyBlock,
                    summary: "x",
                    totalLatencySeconds: 1.0,
                    timeToFirstStreamedContentSeconds: 0.2,
                    errorCategory: nil
                )
            ],
            benchmarkSummary: BenchmarkSummary(
                sampleCount: 3,
                medianTotalLatencySeconds: 1.5,
                minTotalLatencySeconds: 1.0,
                maxTotalLatencySeconds: 2.0,
                medianTimeToFirstStreamedContentSeconds: 0.3,
                minTimeToFirstStreamedContentSeconds: 0.2,
                maxTimeToFirstStreamedContentSeconds: 0.4,
                medianCharactersPerSecond: 20,
                estimatedMedianTokensPerSecond: 5,
                thermalStateBefore: "nominal",
                thermalStateAfter: "nominal",
                batteryPercentageBefore: 80,
                batteryPercentageAfter: 79,
                isCharging: false,
                isLowPowerModeEnabled: false
            ),
            thermalState: "nominal",
            batteryPercentage: 80,
            isCharging: false,
            isLowPowerModeEnabled: false,
            offlinePathObserved: false,
            offlineOutcome: .skipped,
            errorSummaries: [],
            isSimulator: false
        )
    }
}
