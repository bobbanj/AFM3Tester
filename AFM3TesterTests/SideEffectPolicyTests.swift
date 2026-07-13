import FoundationModels
import XCTest
@testable import AFM3Tester

@MainActor
final class SideEffectPolicyTests: XCTestCase {
    func testSideEffectRequiresExplicitUserIntent() {
        XCTAssertTrue(SideEffectPolicy.sideEffectRequiresExplicitUserIntent)
        XCTAssertFalse(SideEffectPolicy.permitsSideEffect(userGrantedPermission: false))
        XCTAssertTrue(SideEffectPolicy.permitsSideEffect(userGrantedPermission: true))
    }

    func testBlocksThemeWithoutPermission() async {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(false)
        let tool = DemoThemeTool(controller: controller)

        do {
            _ = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
            XCTFail("Expected side-effect tool to be blocked without permission")
        } catch {
            XCTAssertTrue(error is DemoThemeError)
        }
    }

    func testAllowsThemeWithPermission() async throws {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(true)
        let tool = DemoThemeTool(controller: controller)

        let result = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
        let theme = await controller.currentTheme
        XCTAssertTrue(result.contains("dark"))
        XCTAssertEqual(theme, "dark")
    }

    func testRejectsInvalidThemeEvenWithPermission() async {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(true)
        let tool = DemoThemeTool(controller: controller)

        do {
            _ = try await tool.call(arguments: SetDemoThemeArguments(theme: "neon"))
            XCTFail("Expected invalid theme rejection")
        } catch {
            XCTAssertTrue(error is DemoThemeError)
        }
    }

    func testPromptInjectionGatingCountsBlockedSideEffect() {
        XCTAssertTrue(
            SideEffectPolicy.shouldCountAsPromptInjectionBlock(
                themeToolCallsBefore: 0,
                themeToolCallsAfter: 0,
                userGrantedPermission: false
            )
        )
        XCTAssertFalse(
            SideEffectPolicy.shouldCountAsPromptInjectionBlock(
                themeToolCallsBefore: 0,
                themeToolCallsAfter: 1,
                userGrantedPermission: false
            )
        )
    }
}
