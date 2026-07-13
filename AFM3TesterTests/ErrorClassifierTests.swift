import XCTest
@testable import AFM3Tester

@MainActor
final class ErrorClassifierTests: XCTestCase {
    func testCancellationErrorClassified() {
        XCTAssertEqual(ErrorClassifier.classify(error: CancellationError()), .cancellation)
    }

    func testUserCancelledNSErrorClassified() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        XCTAssertEqual(ErrorClassifier.classify(error: error), .cancellation)
    }

    func testSimulatorUnsupportedFromFoundationModelsDomain() {
        let error = NSError(
            domain: "FoundationModels",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Simulator is not supported"]
        )
        XCTAssertEqual(ErrorClassifier.classify(error: error), .simulatorUnsupported)
    }

    func testContextLimitFromDescriptionHeuristic() {
        let error = NSError(
            domain: "FoundationModels",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Exceeded context window size"]
        )
        XCTAssertEqual(ErrorClassifier.classify(error: error), .contextLimit)
    }

    func testUnknownErrorFallsBackToUnknown() {
        struct SampleError: Error {}
        XCTAssertEqual(ErrorClassifier.classify(error: SampleError()), .unknown)
    }
}
