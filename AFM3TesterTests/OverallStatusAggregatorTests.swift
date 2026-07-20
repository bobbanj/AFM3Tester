import XCTest
@testable import AFM3Tester

@MainActor
final class OverallStatusAggregatorTests: XCTestCase {
    func testFailedDominates() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.passed, .failed, .expectedPolicyBlock]),
            .failed
        )
    }

    func testExpectedPolicyBlockDoesNotFailRun() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.passed, .expectedPolicyBlock, .skipped]),
            .passed
        )
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.expectedPolicyBlock, .skipped]),
            .expectedPolicyBlock
        )
    }

    func testAllUnavailableIsUnavailable() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.unavailable, .unavailable]),
            .unavailable
        )
    }

    func testMixedUnavailableIsNotSuccessful() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.passed, .unavailable]),
            .failed
        )
    }

    func testSkippedAloneIsSkipped() {
        XCTAssertEqual(OverallStatusAggregator.aggregate([.skipped]), .skipped)
        XCTAssertEqual(OverallStatusAggregator.aggregate([]), .skipped)
    }

    func testSkippedDoesNotCountAsPassed() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.skipped, .observation]),
            .skipped
        )
    }

    func testPartialDoesNotFailOverallRun() {
        XCTAssertEqual(
            OverallStatusAggregator.aggregate([.passed, .partial]),
            .partial
        )
        XCTAssertEqual(
            OverallStatusAggregator.suiteOutcome(fromChecks: [
                ValidationCheck(name: "a", passed: true),
                ValidationCheck(name: "b", passed: true),
                ValidationCheck(name: "c", passed: false)
            ]),
            .partial
        )
    }
}
