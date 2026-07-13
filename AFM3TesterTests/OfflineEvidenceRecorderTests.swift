import XCTest
@testable import AFM3Tester

@MainActor
final class OfflineEvidenceRecorderTests: XCTestCase {
    func testMakeRecordCapturesTimestampsAndPathState() {
        let started = Date(timeIntervalSince1970: 1_700_000_000)
        let completed = Date(timeIntervalSince1970: 1_700_000_030)
        let snapshot = NetworkPathSnapshot(
            statusDescription: "unsatisfied",
            isSatisfied: false,
            availableInterfaces: [],
            capturedAt: completed
        )
        let testResult = TestResult(
            testName: "Offline Verification",
            category: "offline",
            outcome: .passed,
            message: "Inference succeeded while no active network path was observed."
        )

        let record = OfflineEvidenceRecorder.makeRecord(
            startedAt: started,
            completedAt: completed,
            pathSnapshot: snapshot,
            testResult: testResult
        )

        XCTAssertEqual(record.startedAt, started)
        XCTAssertEqual(record.completedAt, completed)
        XCTAssertFalse(record.pathSatisfied)
        XCTAssertEqual(record.networkPathStatus, "unsatisfied")
        XCTAssertTrue(record.monitorDisclaimer.contains("NWPathMonitor"))
        XCTAssertEqual(record.testOutcome, .passed)
    }
}
