import XCTest
@testable import AFM3Tester

@MainActor
final class ReportRedactorTests: XCTestCase {
    func testRedactsEmailAddress() {
        let input = "Contact user@example.com for help."
        let output = ReportRedactor.redact(input)
        XCTAssertTrue(output.contains("[REDACTED_EMAIL]"))
        XCTAssertFalse(output.contains("user@example.com"))
    }

    func testRedactsPhoneNumber() {
        let input = "Call +1 555-123-4567 today."
        let output = ReportRedactor.redact(input)
        XCTAssertTrue(output.contains("[REDACTED_PHONE]"))
    }

    func testRedactsAPIKeyStyleSecrets() {
        let input = "api_key=sk-abcdefghijklmnopqrstuvwxyz123456"
        let output = ReportRedactor.redact(input)
        XCTAssertTrue(output.contains("[REDACTED_SECRET]"))
    }

    func testPreservesBenignText() {
        let input = "Swift concurrency on device."
        XCTAssertEqual(ReportRedactor.redact(input), input)
    }

    @MainActor
    func testRedactsDiagnosticReportFields() {
        let report = DiagnosticReport(
            appVersion: "1.0",
            device: DeviceSnapshot(
                osVersion: "26.0",
                osBuild: "test",
                deviceModel: "iPhone",
                localeIdentifier: "en_US",
                languageCode: "en",
                regionCode: "US",
                thermalState: "nominal",
                batteryLevel: 0.8,
                isLowPowerModeEnabled: false,
                isCharging: false,
                isSimulator: true
            ),
            modelAvailability: "Available",
            modelDescription: "SystemLanguageModel.default",
            testResults: [
                TestResult(
                    testName: "Sample",
                    category: "unit",
                    outcome: .passed,
                    message: "Email user@example.com leaked",
                    rawError: "Bearer abcdefghijklmnopqrst"
                )
            ],
            errors: [
                ErrorLogEntry(
                    testName: "Sample",
                    availabilityState: "Available",
                    localizedDescription: "Phone +1 555-987-6543",
                    debugDescription: "token=sk-abcdefghijklmnopqrstuvwxyz123456",
                    category: .unknown
                )
            ]
        )

        let redacted = ReportRedactor.redactDiagnosticReport(report)
        let encoded = String(data: ReportExporter.exportJSON(report: redacted), encoding: .utf8) ?? ""

        XCTAssertFalse(encoded.contains("user@example.com"))
        XCTAssertFalse(encoded.contains("555-987-6543"))
        XCTAssertFalse(encoded.contains("sk-abcdefghijklmnopqrstuvwxyz123456"))
    }

    func testExporterAlwaysRedactsLegacyPromptOptInReports() {
        let report = DiagnosticReport(
            appVersion: "1.0",
            device: DeviceSnapshot(
                osVersion: "27.0",
                osBuild: "test",
                deviceModel: "iPhone",
                localeIdentifier: "en_US",
                languageCode: "en",
                regionCode: "US",
                thermalState: "nominal",
                batteryLevel: nil,
                isLowPowerModeEnabled: false,
                isCharging: false,
                isSimulator: true
            ),
            modelAvailability: "Available",
            modelDescription: "SystemLanguageModel.default",
            errors: [
                ErrorLogEntry(
                    testName: "Legacy export",
                    availabilityState: "Available",
                    localizedDescription: "Email user@example.com leaked",
                    debugDescription: "api_key=sk-abcdefghijklmnopqrstuvwxyz123456",
                    category: .unknown
                )
            ],
            includePromptText: true,
            promptContents: ["Private prompt from a legacy report"]
        )

        let encoded = String(data: ReportExporter.exportJSON(report: report), encoding: .utf8) ?? ""

        XCTAssertFalse(encoded.contains("user@example.com"))
        XCTAssertFalse(encoded.contains("sk-abcdefghijklmnopqrstuvwxyz123456"))
        XCTAssertFalse(encoded.contains("Private prompt from a legacy report"))
    }
}
