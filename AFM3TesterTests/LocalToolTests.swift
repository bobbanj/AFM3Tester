import FoundationModels
import XCTest
@testable import AFM3Tester

@MainActor
final class LocalToolTests: XCTestCase {
    func testMeridianOSStatusIsDeterministic() async throws {
        let tool = ProjectStatusTool()
        let result = try await tool.call(arguments: GetProjectStatusArguments(projectName: "MeridianOS"))
        XCTAssertTrue(result.localizedCaseInsensitiveContains("MeridianOS"))
    }

    func testBudgetCalculatorTotalsItems() async throws {
        let tool = BudgetCalculatorTool()
        let result = try await tool.call(arguments: CalculateBudgetArguments(items: [
            BudgetLineItem(name: "A", amount: 100),
            BudgetLineItem(name: "B", amount: 200)
        ]))
        XCTAssertTrue(result.contains("300.00"))
    }

    func testBudgetCalculatorRejectsEmptyItems() async {
        let tool = BudgetCalculatorTool()
        let result = try? await tool.call(arguments: CalculateBudgetArguments(items: []))
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.localizedCaseInsensitiveContains("No line items") == true)
    }

    func testUnknownProjectIsRejectedDeterministically() async throws {
        let tool = ProjectStatusTool()
        let result = try await tool.call(arguments: GetProjectStatusArguments(projectName: "UnknownProject"))
        XCTAssertTrue(result.localizedCaseInsensitiveContains("Unknown project"))
    }
}
