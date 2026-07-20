import XCTest
@testable import AFM3Tester

@MainActor
final class ToolPolicyClassifierTests: XCTestCase {
    func testSideEffectsNotAllowedIsExpectedPolicyBlock() {
        let error = DemoThemeError.sideEffectsNotAllowed
        XCTAssertEqual(ToolPolicyClassifier.classify(error), .expectedPolicyBlock)
        XCTAssertTrue(ToolPolicyClassifier.isExpectedSideEffectDenial(error))
    }

    func testInvalidThemeIsInvalidArguments() {
        XCTAssertEqual(
            ToolPolicyClassifier.classify(DemoThemeError.invalidTheme("neon")),
            .invalidArguments
        )
    }

    func testUnauthorizedSideEffectRejection() async {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(false)
        let tool = DemoThemeTool(controller: controller)
        do {
            _ = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
            XCTFail("Expected denial")
        } catch {
            XCTAssertEqual(ToolPolicyClassifier.classify(error), .expectedPolicyBlock)
        }
    }

    func testAuthorizedSideEffectExecution() async throws {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(true)
        let tool = DemoThemeTool(controller: controller)
        let result = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
        XCTAssertTrue(result.contains("dark"))
        let theme = await controller.currentTheme
        XCTAssertEqual(theme, "dark")
    }

    func testQuotedContentPermissionIsolationLogic() {
        XCTAssertTrue(
            SideEffectPolicy.shouldCountAsPromptInjectionBlock(
                themeToolCallsBefore: 1,
                themeToolCallsAfter: 1,
                userGrantedPermission: false
            )
        )
        XCTAssertFalse(
            SideEffectPolicy.shouldCountAsPromptInjectionBlock(
                themeToolCallsBefore: 1,
                themeToolCallsAfter: 2,
                userGrantedPermission: false
            )
        )
    }
}
