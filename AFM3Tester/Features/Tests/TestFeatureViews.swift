import SwiftUI
import UniformTypeIdentifiers

struct StructuredOutputView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var prettyOutput = ""
    @State private var lastResult: TestResult?

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Guided generation using @Generable types: MeetingSummary and SupportTicketClassification.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Structured Output Tests", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        let result = await TestRunners.structuredOutputTest(service: service, store: store)
                        lastResult = result
                        prettyOutput = result.message ?? ""
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }

                if !prettyOutput.isEmpty {
                    GroupBox("Generated Structure") {
                        Text(prettyOutput)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Structured Output")
        }
    }
}

struct ToolCallingView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var lastResult: TestResult?
    @State private var allowSideEffects = false

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Local tools only: getProjectStatus, calculateBudget, setDemoTheme.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Toggle("Allow side-effect tools (explicit user intent for setDemoTheme)", isOn: $allowSideEffects)
                    .onChange(of: allowSideEffects) { _, newValue in
                        store.allowSideEffectTools = newValue
                    }

                RunTestButton(title: isRunning ? "Running…" : "Run Tool Calling Tests", isRunning: isRunning) {
                    store.allowSideEffectTools = allowSideEffects
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.toolTests(service: service, store: store)
                        await store.syncDemoThemeFromController()
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }

                if !store.toolInvocationLog.isEmpty {
                    GroupBox("Tool Invocations") {
                        ForEach(store.toolInvocationLog.suffix(10)) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.toolName).font(.caption.weight(.semibold))
                                Text("Args: \(record.argumentsJSON)").font(.caption2)
                                Text("Result: \(record.result)").font(.caption2)
                            }
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle("Tool Calling")
        }
    }
}

struct ConversationMemoryView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var lastResult: TestResult?
    @State private var transcriptDump = ""

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Multi-turn session memory and transcript rehydration (in-memory only, not persisted to disk).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Memory Test", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.memoryTest(service: service, store: store)
                        transcriptDump = lastResult?.message ?? ""
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }

                if !transcriptDump.isEmpty {
                    GroupBox("Transcript") {
                        Text(transcriptDump)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Conversation Memory")
        }
    }
}

struct MultilingualView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var results: [TestResult] = []
    @State private var ratings: [String: ManualQualityRating] = [:]

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Automatic checks measure non-empty output, length, and timing — not linguistic quality.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Multilingual Test", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        let result = await TestRunners.multilingualTest(service: service, store: store)
                        results = [result]
                        isRunning = false
                    }
                }

                ForEach(results) { result in
                    TestResultCard(result: result)
                }

                GroupBox("Manual Quality Rating") {
                    ForEach(["English", "Swedish", "German", "Spanish", "Arabic"], id: \.self) { language in
                        HStack {
                            Text(language)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { ratings[language] ?? .acceptable },
                                set: { ratings[language] = $0 }
                            )) {
                                ForEach(ManualQualityRating.allCases, id: \.self) { rating in
                                    Text(rating.rawValue.capitalized).tag(rating)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 280)
                        }
                    }
                }
            }
            .navigationTitle("Multilingual")
        }
    }
}

struct SafetyTestsView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var lastResult: TestResult?

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Label(
                    "Behavioral observations only — not a security certification.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Safety Tests", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.safetyTests(service: service, store: store)
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }
            }
            .navigationTitle("Safety Tests")
        }
    }
}

struct ContextWindowView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var lastResult: TestResult?

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Token counts are estimates (~4 characters per token) unless the SDK returns an official tokenCount. Stops safely on context-size errors.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Context Window Test", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.contextWindowTest(service: service, store: store)
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }
            }
            .navigationTitle("Context Window")
        }
    }
}

struct ConcurrencyView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false
    @State private var lastResult: TestResult?

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Text("Tests 1, 2 sequential, 2 concurrent, and 4 concurrent requests (max 4). Records thermal and battery state.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                RunTestButton(title: isRunning ? "Running…" : "Run Concurrency Test", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.concurrencyTest(service: service, store: store)
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }
            }
            .navigationTitle("Concurrency")
        }
    }
}

struct BenchmarkView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Label(
                    "Benchmark results are beta-software observations on this device and are not an official measure of model capability.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)

                RunTestButton(title: isRunning ? "Running…" : "Run Benchmark (3 reps)", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        _ = await TestRunners.benchmarkTest(service: service, store: store)
                        isRunning = false
                    }
                }

                ForEach(store.benchmarks.suffix(9)) { sample in
                    GroupBox("\(sample.testName) — rep \(sample.repetition)") {
                        LatencyMetricsView(metrics: sample.latency)
                        InfoRow(label: "Thermal", value: sample.thermalState)
                        InfoRow(label: "Battery", value: sample.batteryLevel.map { String(format: "%.0f%%", $0 * 100) } ?? "N/A")
                        InfoRow(label: "Low Power", value: sample.isLowPowerModeEnabled ? "Yes" : "No")
                        InfoRow(label: "Charging", value: sample.isCharging ? "Yes" : "No")
                    }
                }
            }
            .navigationTitle("Benchmark")
        }
    }
}

struct OfflineVerificationView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var monitor = NetworkPathMonitorService()
    @State private var pathSnapshot = NetworkPathSnapshot(
        statusDescription: "Starting…",
        isSatisfied: true,
        availableInterfaces: []
    )
    @State private var isRunning = false
    @State private var lastResult: TestResult?

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                GroupBox("Instructions") {
                    Text("""
                    1. Manually enable Airplane Mode on your iPhone.
                    2. Disable Wi‑Fi if it remains active after Airplane Mode.
                    3. Verify the network path below shows no satisfied path.
                    4. Run offline tests and export the report.

                    The app does not toggle Airplane Mode. NWPathMonitor cannot prove that every radio is disabled.
                    """)
                        .font(.subheadline)
                }

                GroupBox("Observed Network Path") {
                    InfoRow(label: "Status", value: pathSnapshot.statusDescription)
                    InfoRow(label: "Path Satisfied", value: pathSnapshot.isSatisfied ? "Yes" : "No")
                    InfoRow(
                        label: "Interfaces",
                        value: pathSnapshot.availableInterfaces.isEmpty
                            ? "none reported"
                            : pathSnapshot.availableInterfaces.joined(separator: ", ")
                    )
                    InfoRow(
                        label: "Captured",
                        value: pathSnapshot.capturedAt.formatted(date: .abbreviated, time: .standard)
                    )
                }

                RunTestButton(title: isRunning ? "Running…" : "Run Offline Tests", isRunning: isRunning) {
                    Task {
                        isRunning = true
                        lastResult = await TestRunners.offlineTests(
                            service: service,
                            store: store,
                            networkMonitor: monitor
                        )
                        pathSnapshot = await monitor.currentSnapshot()
                        isRunning = false
                    }
                }

                if let result = lastResult {
                    TestResultCard(result: result)
                }

                if !store.offlineEvidenceRecords.isEmpty {
                    GroupBox("Recorded Offline Evidence") {
                        ForEach(store.offlineEvidenceRecords.reversed()) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.startedAt.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption.bold())
                                Text("Outcome: \(record.testOutcome.rawValue)")
                                    .font(.caption)
                                Text("Path: \(record.networkPathStatus)")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Offline Test")
            .task {
                await monitor.start()
                await refreshPath()
            }
            .onDisappear {
                Task { await monitor.stop() }
            }
        }
    }

    private func refreshPath() async {
        pathSnapshot = await monitor.currentSnapshot()
    }
}

struct ErrorExplorerView: View {
    let store: DiagnosticStore

    var body: some View {
        NavigationStack {
            List(store.errorLog.reversed()) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.testName).font(.headline)
                        Spacer()
                        Text(entry.category.rawValue)
                            .font(.caption2)
                            .padding(4)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Availability: \(entry.availabilityState)")
                        .font(.caption)
                    Text(entry.localizedDescription).font(.subheadline)
                    Text(entry.debugDescription)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Error Explorer")
            .overlay {
                if store.errorLog.isEmpty {
                    ContentUnavailableView("No Errors Logged", systemImage: "checkmark.circle")
                }
            }
        }
    }
}

struct ExportView: View {
    @Bindable var store: DiagnosticStore

    @State private var jsonData: Data?
    @State private var markdown = ""

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                Toggle("Include prompt text in export", isOn: $store.includePromptsInExport)

                Text("Sensitive patterns (emails, phones, API keys) are redacted automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Prepare Export") {
                    let report = ReportExporter.buildReport(from: store)
                    jsonData = ReportExporter.exportJSON(report: report)
                    markdown = ReportExporter.exportMarkdown(report: report)
                }
                .buttonStyle(.borderedProminent)

                if let jsonData {
                    ShareLink(item: jsonData, preview: SharePreview("AFM3Tester Report.json")) {
                        Label("Share JSON Report", systemImage: "doc.badge.gearshape")
                    }
                }

                if !markdown.isEmpty {
                    ShareLink(item: markdown, preview: SharePreview("AFM3Tester Report.md")) {
                        Label("Share Markdown Report", systemImage: "doc.richtext")
                    }

                    GroupBox("Markdown Preview") {
                        Text(markdown.prefix(2000) + (markdown.count > 2000 ? "\n…" : ""))
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Export")
        }
    }
}

extension Data: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { data in
            data
        }
    }
}
