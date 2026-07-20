import Foundation
import SwiftUI

// Interactive debug self-tests for the Overview tab (#if DEBUG).
// These are diagnostic conveniences only — canonical automated coverage lives in AFM3TesterTests (XCTest).

struct ReportRedactorTests {

    static func runAll() -> [(name: String, passed: Bool)] {
        [
            ("redacts email", testRedactsEmail()),
            ("redacts phone", testRedactsPhone()),
            ("preserves latency metrics", testPreservesLatencyMetrics()),
            ("redacts api key pattern", testRedactsAPIKey()),
            ("preserves benign text", testPreservesBenignText())
        ]
    }

    private static func testRedactsEmail() -> Bool {
        let input = "Contact user@example.com for help."
        return ReportRedactor.redact(input).contains("[REDACTED_EMAIL]")
            && !ReportRedactor.redact(input).contains("user@example.com")
    }

    private static func testRedactsPhone() -> Bool {
        let input = "Call +1 555-123-4567 today."
        let output = ReportRedactor.redact(input)
        return output.contains("[REDACTED_PHONE]")
    }

    private static func testPreservesLatencyMetrics() -> Bool {
        let input = "Latency: 1.234567s on iPhone18,2"
        let output = ReportRedactor.redactFreeTextPreservingMetrics(input)
        return output.contains("1.234567") && !output.contains("[REDACTED_PHONE]")
    }

    private static func testRedactsAPIKey() -> Bool {
        let input = "api_key=sk-abcdefghijklmnopqrstuvwxyz123456"
        let output = ReportRedactor.redact(input)
        return output.contains("[REDACTED_SECRET]")
    }

    private static func testPreservesBenignText() -> Bool {
        let input = "Swift concurrency on device."
        return ReportRedactor.redact(input) == input
    }
}

struct ValidationLogicTests {

    static func runAll() -> [(name: String, passed: Bool)] {
        [
            ("valid sentiment accepted", testValidSentiment()),
            ("invalid sentiment rejected", testInvalidSentiment()),
            ("expected owners subset", testExpectedOwners())
        ]
    }

    private static func testValidSentiment() -> Bool {
        let valid = ["positive", "neutral", "mixed", "negative"]
        return valid.allSatisfy { valid.contains($0.lowercased()) }
    }

    private static func testInvalidSentiment() -> Bool {
        let valid = Set(["positive", "neutral", "mixed", "negative"])
        return !valid.contains("ecstatic")
    }

    private static func testExpectedOwners() -> Bool {
        let expected = Set(["Alex", "Morgan", "Team", "Casey", "Jordan"])
        let actual = Set(["Alex", "Morgan"])
        return actual.isSubset(of: expected)
    }
}

struct LocalToolTests {

    static func runAll() async -> [(name: String, passed: Bool)] {
        await [
            ("Project Atlas status", testProjectAtlasStatus()),
            ("budget total", testBudgetTotal()),
            ("invalid project rejected", testInvalidProject())
        ]
    }

    private static func testProjectAtlasStatus() async -> Bool {
        let tool = ProjectStatusTool()
        let args = GetProjectStatusArguments(projectName: "Project Atlas")
        let result = try? await tool.call(arguments: args)
        return result?.localizedCaseInsensitiveContains("Project Atlas") == true
    }

    private static func testBudgetTotal() async -> Bool {
        let tool = BudgetCalculatorTool()
        let args = CalculateBudgetArguments(items: [
            BudgetLineItem(name: "A", amount: 100),
            BudgetLineItem(name: "B", amount: 200)
        ])
        let result = try? await tool.call(arguments: args)
        return result?.contains("300") == true
    }

    private static func testInvalidProject() async -> Bool {
        let tool = ProjectStatusTool()
        let args = GetProjectStatusArguments(projectName: "UnknownProject")
        let result = try? await tool.call(arguments: args)
        return result?.localizedCaseInsensitiveContains("Unknown project") == true
    }
}

struct PromptInjectionGatingTests {

    static func runAll() async -> [(name: String, passed: Bool)] {
        await [
            ("blocks theme without permission", testBlocksThemeWithoutPermission()),
            ("allows theme with permission", testAllowsThemeWithPermission()),
            ("rejects invalid theme", testRejectsInvalidTheme())
        ]
    }

    private static func testBlocksThemeWithoutPermission() async -> Bool {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(false)
        let tool = DemoThemeTool(controller: controller)
        do {
            _ = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
            return false
        } catch {
            return true
        }
    }

    private static func testAllowsThemeWithPermission() async -> Bool {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(true)
        let tool = DemoThemeTool(controller: controller)
        do {
            let result = try await tool.call(arguments: SetDemoThemeArguments(theme: "dark"))
            let theme = await controller.currentTheme
            return result.contains("dark") && theme == "dark"
        } catch {
            return false
        }
    }

    private static func testRejectsInvalidTheme() async -> Bool {
        let controller = DemoThemeController()
        await controller.setAllowSideEffects(true)
        let tool = DemoThemeTool(controller: controller)
        do {
            _ = try await tool.call(arguments: SetDemoThemeArguments(theme: "neon"))
            return false
        } catch {
            return true
        }
    }
}

enum AFM3TesterSelfTestRunner {

    @MainActor
    static func runEmbeddedSelfTests(store: DiagnosticStore) async {
        var checks: [ValidationCheck] = []

        for test in ReportRedactorTests.runAll() {
            checks.append(ValidationCheck(name: "ReportRedactor: \(test.name)", passed: test.passed))
        }
        for test in ValidationLogicTests.runAll() {
            checks.append(ValidationCheck(name: "Validation: \(test.name)", passed: test.passed))
        }
        for test in await LocalToolTests.runAll() {
            checks.append(ValidationCheck(name: "LocalTool: \(test.name)", passed: test.passed))
        }
        for test in await PromptInjectionGatingTests.runAll() {
            checks.append(ValidationCheck(name: "ToolGating: \(test.name)", passed: test.passed))
        }

        let allPassed = checks.allSatisfy(\.passed)
        store.recordTest(TestResult(
            testName: "Embedded Unit Self-Tests",
            category: "unit",
            outcome: allPassed ? .passed : .failed,
            message: "\(checks.filter(\.passed).count)/\(checks.count) checks passed",
            validationChecks: checks
        ))
    }
}

#if DEBUG
struct UnitTestDebugView: View {
    let store: DiagnosticStore
    @State private var ran = false

    var body: some View {
        Button("Run Embedded Unit Self-Tests") {
            Task {
                await AFM3TesterSelfTestRunner.runEmbeddedSelfTests(store: store)
                ran = true
            }
        }
        .buttonStyle(.bordered)
        if ran, let result = store.testResults["Embedded Unit Self-Tests"] {
            TestResultCard(result: result)
        }
    }
}
#endif
