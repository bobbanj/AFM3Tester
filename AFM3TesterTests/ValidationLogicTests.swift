import FoundationModels
import XCTest
@testable import AFM3Tester

@MainActor
final class ValidationLogicTests: XCTestCase {
    func testValidSentimentsAccepted() {
        for sentiment in ["positive", "neutral", "mixed", "negative"] {
            XCTAssertTrue(StructuredOutputValidator.isValidSentiment(sentiment))
        }
    }

    func testInvalidSentimentRejected() {
        XCTAssertFalse(StructuredOutputValidator.isValidSentiment("ecstatic"))
    }

    func testExpectedOwnersSubset() {
        let actual = Set(["Alex", "Morgan"])
        let allowed = StructuredOutputValidator.defaultExpectedOwners
        XCTAssertTrue(StructuredOutputValidator.ownersAreExpected(actual, allowed: allowed))
    }

    func testUnexpectedOwnerRejected() {
        let actual = Set(["Alex", "UnknownPerson"])
        let allowed = StructuredOutputValidator.defaultExpectedOwners
        XCTAssertFalse(StructuredOutputValidator.ownersAreExpected(actual, allowed: allowed))
    }

    func testValidateMeetingSummaryPassesForWellFormedSummary() {
        let summary = MeetingSummary(
            title: "Launch Review",
            conciseSummary: "Team reviewed the launch timeline.",
            sentiment: "positive",
            actionItems: [
                ActionItem(owner: "Alex", task: "Ship docs", deadline: "Friday"),
                ActionItem(owner: "Morgan", task: "QA pass", deadline: nil)
            ],
            risks: ["Schedule slip"]
        )

        let checks = StructuredOutputValidator.validateMeetingSummary(summary)
        XCTAssertTrue(checks.allSatisfy { $0.passed }, checks.description)
    }

    func testValidateSupportTicketsChecksCountAndSchema() {
        let tickets = (1 ... 10).map { index in
            SupportTicketClassification(
                category: "billing",
                priority: min(index, 5),
                summary: "Ticket \(index)",
                requiresHuman: false
            )
        }

        let checks = StructuredOutputValidator.validateSupportTickets(tickets)
        XCTAssertTrue(checks.allSatisfy(\.passed))
    }
}
