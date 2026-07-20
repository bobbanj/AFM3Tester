import XCTest
@testable import AFM3Tester

@MainActor
final class OfflineObservationFormatterTests: XCTestCase {
    func testNotRunWhenOfflineAbsent() {
        let run = sampleRun(offlineOutcome: nil, suiteOffline: false)
        XCTAssertEqual(OfflineObservationFormatter.deviceReportLabel(for: run), "Not Run")
    }

    func testPassedWithChecksAndEvidence() {
        let run = sampleRun(
            offlineOutcome: .passed,
            pathObserved: true,
            checksPassed: 4,
            checksTotal: 4
        )
        XCTAssertEqual(
            OfflineObservationFormatter.deviceReportLabel(for: run),
            "Passed (4/4 checks, NWPathMonitor evidence)"
        )
    }

    func testPartialWithChecks() {
        let run = sampleRun(
            offlineOutcome: .partial,
            pathObserved: true,
            checksPassed: 3,
            checksTotal: 4
        )
        XCTAssertEqual(
            OfflineObservationFormatter.deviceReportLabel(for: run),
            "Partial (3/4 checks, NWPathMonitor evidence)"
        )
    }

    func testFallsBackToSuiteResultWhenOfflineOutcomeMissing() {
        let run = sampleRun(offlineOutcome: nil, suiteOffline: true, suiteOutcome: .passed)
        XCTAssertEqual(OfflineObservationFormatter.deviceReportLabel(for: run), "Passed")
    }

    private func sampleRun(
        offlineOutcome: TestOutcome?,
        pathObserved: Bool? = nil,
        checksPassed: Int? = nil,
        checksTotal: Int? = nil,
        suiteOffline: Bool = false,
        suiteOutcome: TestOutcome = .passed
    ) -> DiagnosticRunRecord {
        var suites: [StoredSuiteResult] = []
        if suiteOffline {
            suites.append(
                StoredSuiteResult(
                    suiteName: OfflineObservationFormatter.suiteName,
                    category: "offline",
                    outcome: suiteOutcome,
                    summary: "offline",
                    totalLatencySeconds: nil,
                    timeToFirstStreamedContentSeconds: nil,
                    errorCategory: nil
                )
            )
        }
        return DiagnosticRunRecord(
            appVersion: "0.2.2",
            appBuild: "4",
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
            overallStatus: .passed,
            overallSummary: "Passed",
            suiteResults: suites,
            benchmarkSummary: nil,
            thermalState: "nominal",
            batteryPercentage: 80,
            isCharging: false,
            isLowPowerModeEnabled: false,
            offlinePathObserved: pathObserved,
            offlineOutcome: offlineOutcome,
            offlineChecksPassed: checksPassed,
            offlineChecksTotal: checksTotal,
            offlineCompletedAt: Date(),
            errorSummaries: [],
            policyEventSummaries: [],
            isSimulator: false
        )
    }
}
