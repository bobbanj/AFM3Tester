import Foundation
import SwiftUI

@MainActor
@Observable
final class DiagnosticStore: DiagnosticRecording {
    static let shared = DiagnosticStore()

    var errorLog: [ErrorLogEntry] = []
    var policyEvents: [PolicyEventEntry] = []
    var testResults: [String: TestResult] = [:]
    var benchmarks: [BenchmarkSample] = []
    /// Benchmark samples from the most recent benchmark run only.
    var currentBenchmarkSamples: [BenchmarkSample] = []
    var lastBenchmarkSummary: BenchmarkSummary?
    var lastSuccessfulInference: Date?
    var demoTheme: ColorScheme?
    var allowSideEffectTools = false
    var toolInvocationLog: [ToolInvocationRecord] = []
    var offlineEvidenceRecords: [OfflineEvidenceRecord] = []
    var lastOverallStatus: OverallRunStatus?
    var lastOverallSummary: String?
    var lastSavedRunID: UUID?

    /// Set while `runAllSafeTests` orchestration is in progress.
    var isRunningAllSafeTests = false
    /// True while any non-benchmark inference suite is actively running from the UI.
    var isInferenceBusy = false
    var isRunningBenchmark = false

    let themeController = DemoThemeController()
    let historyStore = TestHistoryStore.shared

    private init() {}

    func recordError(_ entry: ErrorLogEntry) {
        errorLog.append(entry)
    }

    nonisolated func recordError(_ entry: ErrorLogEntry) async {
        await MainActor.run {
            self.recordError(entry)
        }
    }

    func recordPolicyEvent(_ entry: PolicyEventEntry) {
        policyEvents.append(entry)
    }

    nonisolated func recordPolicyEvent(_ entry: PolicyEventEntry) async {
        await MainActor.run {
            self.recordPolicyEvent(entry)
        }
    }

    func recordTest(_ result: TestResult) {
        testResults[result.testName] = result
    }

    func recordBenchmark(_ sample: BenchmarkSample) {
        benchmarks.append(sample)
        currentBenchmarkSamples.append(sample)
    }

    func beginBenchmarkRun() {
        currentBenchmarkSamples = []
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

    func copyGitHubDeviceReport(availability: String, contextSize: Int?) -> String {
        let run = DiagnosticRunFactory.makeRun(
            from: self,
            availability: availability,
            contextSize: contextSize
        )
        return GitHubDeviceReportExporter.makeMarkdown(from: run)
    }

    func copyEnvironmentSummary(availability: String, contextSize: Int?) -> String {
        let device = DeviceInfoProvider.captureSnapshot()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "4"
        return """
        AFM3Tester Environment Summary
        Version: \(version)
        Build: \(build)
        Device: \(device.marketingName)
        Hardware identifier: \(device.deviceModel)
        OS: \(device.osVersion) (\(device.osBuild))
        Availability: \(availability)
        Deployment: \(FoundationModelService.deployment)
        Context Size: \(contextSize.map(String.init) ?? "n/a")
        Locale: \(device.localeIdentifier)
        Region: \(device.regionCode)
        """
    }

    func currentOverallStatus() -> OverallRunStatus {
        OverallStatusAggregator.aggregate(testResults.values.map(\.outcome))
    }

    func persistCurrentRun(availability: String, contextSize: Int?) {
        let run = DiagnosticRunFactory.makeRun(
            from: self,
            availability: availability,
            contextSize: contextSize
        )
        lastOverallStatus = run.overallStatus
        lastOverallSummary = run.overallSummary
        lastSavedRunID = run.id
        historyStore.saveRun(run)
    }

    /// Orchestration: runs safe suites sequentially. Context Window runs last.
    func runAllSafeTests(service: FoundationModelService) async {
        guard !isRunningAllSafeTests else { return }
        isRunningAllSafeTests = true
        isInferenceBusy = true
        defer {
            isRunningAllSafeTests = false
            isInferenceBusy = false
        }

        _ = await TestRunners.structuredOutputTest(service: service, store: self)
        _ = await TestRunners.memoryTest(service: service, store: self)
        _ = await TestRunners.toolTests(service: service, store: self)
        _ = await TestRunners.multilingualTest(service: service, store: self)
        _ = await TestRunners.safetyTests(service: service, store: self)
        _ = await TestRunners.concurrencyTest(service: service, store: self)
        _ = await TestRunners.benchmarkTest(service: service, store: self)
        // Context intentionally last: it may push context limits and must not poison later suites.
        _ = await TestRunners.contextWindowTest(service: service, store: self)

        let availability = await service.availabilityDescription
        let contextSize = await service.contextSize
        persistCurrentRun(availability: availability, contextSize: contextSize)
    }

    func syncDemoThemeFromController() async {
        let theme = await themeController.currentTheme
        demoTheme = theme == "dark" ? .dark : .light
    }
}
