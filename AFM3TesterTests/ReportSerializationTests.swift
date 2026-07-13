import XCTest
@testable import AFM3Tester

@MainActor
final class ReportSerializationTests: XCTestCase {
    func testDiagnosticReportEncodesAndDecodes() throws {
        let report = DiagnosticReport(
            appVersion: "1.0",
            device: DeviceSnapshot(
                osVersion: "27.0",
                osBuild: "24A000",
                deviceModel: "iPhone",
                localeIdentifier: "en_US",
                languageCode: "en",
                regionCode: "US",
                thermalState: "nominal",
                batteryLevel: 0.75,
                isLowPowerModeEnabled: false,
                isCharging: true,
                isSimulator: false
            ),
            modelAvailability: "Available",
            modelDescription: ModelMetadataFormatter.apiModelIdentifier,
            deploymentType: "On-Device (SystemLanguageModel)",
            contextWindowSize: 8192,
            contextWindowExposed: true,
            testResults: [
                TestResult(testName: "Basic", category: "generation", outcome: .passed, message: "ok")
            ],
            offlineEvidenceRecords: [
                OfflineEvidenceRecord(
                    startedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    completedAt: Date(timeIntervalSince1970: 1_700_000_010),
                    networkPathStatus: "unsatisfied",
                    pathSatisfied: false,
                    availableInterfaces: [],
                    monitorDisclaimer: SideEffectPolicy.monitorDisclaimer,
                    testOutcome: .passed,
                    checks: [],
                    message: "Observed run"
                )
            ]
        )

        let data = ReportExporter.exportJSON(report: report)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticReport.self, from: data)

        XCTAssertEqual(decoded.appVersion, "1.0")
        XCTAssertEqual(decoded.offlineEvidenceRecords.count, 1)
        XCTAssertEqual(decoded.testResults.first?.testName, "Basic")
    }

    func testMarkdownExportIncludesOfflineDisclaimer() {
        let report = DiagnosticReport(
            appVersion: "1.0",
            device: DeviceSnapshot(
                osVersion: "27.0",
                osBuild: "24A000",
                deviceModel: "iPhone",
                localeIdentifier: "en_US",
                languageCode: "en",
                regionCode: "US",
                thermalState: "nominal",
                batteryLevel: nil,
                isLowPowerModeEnabled: false,
                isCharging: false,
                isSimulator: false
            ),
            modelAvailability: "Available",
            modelDescription: ModelMetadataFormatter.apiModelIdentifier,
            offlineTestSucceeded: false
        )

        let markdown = ReportExporter.exportMarkdown(report: report)
        XCTAssertTrue(markdown.contains("NWPathMonitor reports path status only"))
        XCTAssertTrue(markdown.contains("Not exposed by public SDK property"))
    }
}
