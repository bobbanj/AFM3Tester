import XCTest
@testable import AFM3Tester

@MainActor
final class ContextTestFixturesTests: XCTestCase {
    func testFilteredPromptsRespectContextLimit() {
        let prompts = ContextTestFixtures.filteredPrompts(for: 8_192)
        XCTAssertFalse(prompts.isEmpty)
        XCTAssertTrue(prompts.allSatisfy { $0.targetTokens <= 8_192 - 256 })
    }

    func testFilteredPromptsNeverReturnEmptyForLargeLimit() {
        let prompts = ContextTestFixtures.filteredPrompts(for: 16_384)
        XCTAssertEqual(prompts.count, SampleContent.contextWindowPrompts.count)
    }
}
