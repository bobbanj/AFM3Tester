import Foundation
import SwiftUI

@MainActor
@Observable
final class DiagnosticStore: DiagnosticRecording {
    static let shared = DiagnosticStore()

    var errorLog: [ErrorLogEntry] = []
    var testResults: [String: TestResult] = [:]
    var benchmarks: [BenchmarkSample] = []
    var lastSuccessfulInference: Date?
    var includePromptsInExport = false
    var demoTheme: ColorScheme?
    var allowSideEffectTools = false
    var toolInvocationLog: [ToolInvocationRecord] = []
    var offlineEvidenceRecords: [OfflineEvidenceRecord] = []

    /// Set while `runAllSafeTests` orchestration is in progress.
    var isRunningAllSafeTests = false

    let themeController = DemoThemeController()

    private init() {}

    func recordError(_ entry: ErrorLogEntry) {
        errorLog.append(entry)
    }

    nonisolated func recordError(_ entry: ErrorLogEntry) async {
        await MainActor.run {
            self.recordError(entry)
        }
    }

    func recordTest(_ result: TestResult) {
        testResults[result.testName] = result
    }

    func recordBenchmark(_ sample: BenchmarkSample) {
        benchmarks.append(sample)
    }

    func recordToolInvocation(_ record: ToolInvocationRecord) {
        toolInvocationLog.append(record)
    }

    func recordOfflineEvidence(_ record: OfflineEvidenceRecord) {
        offlineEvidenceRecords.append(record)
    }

    func markSuccessfulInference() {
        lastSuccessfulInference = Date()
    }

    func copyDiagnosticReport() -> String {
        let report = ReportExporter.buildReport(from: self)
        return ReportExporter.exportMarkdown(report: report)
    }

    /// Orchestration stub: sets flags and runs safe test suites sequentially.
    func runAllSafeTests(service: FoundationModelService) async {
        guard !isRunningAllSafeTests else { return }
        isRunningAllSafeTests = true
        defer { isRunningAllSafeTests = false }

        _ = await TestRunners.structuredOutputTest(service: service, store: self)
        _ = await TestRunners.memoryTest(service: service, store: self)
        _ = await TestRunners.toolTests(service: service, store: self)
        _ = await TestRunners.multilingualTest(service: service, store: self)
        _ = await TestRunners.safetyTests(service: service, store: self)
        _ = await TestRunners.contextWindowTest(service: service, store: self)
        _ = await TestRunners.concurrencyTest(service: service, store: self)
        _ = await TestRunners.benchmarkTest(service: service, store: self)
    }

    func syncDemoThemeFromController() async {
        let theme = await themeController.currentTheme
        demoTheme = theme == "dark" ? .dark : .light
    }
}
