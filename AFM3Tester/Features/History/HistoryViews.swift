import SwiftUI

struct HistoryListView: View {
    @Bindable var store: DiagnosticStore
    @State private var selection = Set<UUID>()
    @State private var compareLeft: DiagnosticRunRecord?
    @State private var compareRight: DiagnosticRunRecord?
    @State private var showCompare = false

    private var history: TestHistoryStore { store.historyStore }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Beta-software observations from this device and build.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let error = history.lastLoadError {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Runs") {
                    if history.runs.isEmpty {
                        Text("No local history yet. Run All Safe Tests to create a record.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(history.runs) { run in
                            NavigationLink {
                                HistoryDetailView(run: run, store: store)
                            } label: {
                                HistoryRowView(run: run, isSelected: selection.contains(run.id))
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    history.deleteRun(id: run.id)
                                    selection.remove(run.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(selection.contains(run.id) ? "Deselect for compare" : "Select for compare") {
                                    toggleSelection(run.id)
                                }
                            }
                        }
                    }
                }

                if selection.count == 2 {
                    Section {
                        Button("Compare selected runs") {
                            let ids = Array(selection)
                            compareLeft = history.run(id: ids[0])
                            compareRight = history.run(id: ids[1])
                            showCompare = compareLeft != nil && compareRight != nil
                        }
                    }
                }

                Section {
                    Button("Delete All History", role: .destructive) {
                        history.deleteAll()
                        selection.removeAll()
                    }
                    .disabled(history.runs.isEmpty)
                }
            }
            .navigationTitle("History")
            .navigationDestination(isPresented: $showCompare) {
                if let left = compareLeft, let right = compareRight {
                    CompareRunsView(left: left, right: right)
                }
            }
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            if selection.count >= 2, let first = selection.first {
                selection.remove(first)
            }
            selection.insert(id)
        }
    }
}

struct HistoryRowView: View {
    let run: DiagnosticRunRecord
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(run.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
                OverallStatusBadge(status: run.overallStatus)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            Text("\(run.marketingName) · \(run.hardwareIdentifier)")
                .font(.caption)
            Text("OS \(run.osVersion) (\(run.osBuild))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Availability: \(run.availability)")
                .font(.caption2)
            if let latency = run.benchmarkSummary?.medianTotalLatencySeconds
                ?? run.suiteResults.compactMap(\.totalLatencySeconds).first {
                Text(String(format: "Basic latency: %.3fs", latency))
                    .font(.caption2)
            }
            Text("Offline: \(OfflineObservationFormatter.deviceReportLabel(for: run))")
                .font(.caption2)
        }
        .padding(.vertical, 2)
    }
}

struct HistoryDetailView: View {
    let run: DiagnosticRunRecord
    let store: DiagnosticStore

    var body: some View {
        DiagnosticScrollScreen {
            Text("Beta-software observations from this device and build.")
                .font(.caption)
                .foregroundStyle(.secondary)

            GroupBox("Run") {
                InfoRow(label: "When", value: run.timestamp.formatted(date: .complete, time: .standard))
                InfoRow(label: "Overall", value: run.overallSummary)
                InfoRow(label: "App", value: "\(run.appVersion) (\(run.appBuild))")
            }

            GroupBox("Device") {
                InfoRow(label: "Marketing name", value: run.marketingName)
                InfoRow(label: "Hardware ID", value: run.hardwareIdentifier)
                InfoRow(label: "OS", value: "\(run.osVersion) (\(run.osBuild))")
                InfoRow(label: "Locale", value: run.localeIdentifier)
                InfoRow(label: "Region", value: run.regionCode)
            }

            GroupBox("Model") {
                InfoRow(label: "API", value: run.modelAPIIdentifier)
                InfoRow(label: "Availability", value: run.availability)
                InfoRow(label: "Deployment", value: run.deploymentObservation)
                InfoRow(label: "Context size", value: run.contextSize.map(String.init) ?? "n/a")
                InfoRow(label: "Offline Verification", value: OfflineObservationFormatter.deviceReportLabel(for: run))
            }

            GroupBox("Suites") {
                ForEach(run.suiteResults) { suite in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(suite.suiteName).font(.subheadline.weight(.semibold))
                            if let summary = suite.summary {
                                Text(summary).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        OutcomeBadge(outcome: suite.outcome)
                    }
                    .padding(.vertical, 2)
                }
            }

            if let bench = run.benchmarkSummary {
                GroupBox("Benchmark") {
                    InfoRow(label: "Samples", value: "\(bench.sampleCount)")
                    InfoRow(label: "Median total", value: format(bench.medianTotalLatencySeconds))
                    InfoRow(label: "Min / max", value: "\(format(bench.minTotalLatencySeconds)) / \(format(bench.maxTotalLatencySeconds))")
                    InfoRow(label: "Median TTFS", value: format(bench.medianTimeToFirstStreamedContentSeconds))
                    InfoRow(label: "Chars/sec", value: bench.medianCharactersPerSecond.map { String(format: "%.1f", $0) } ?? "n/a")
                    if let est = bench.estimatedMedianTokensPerSecond {
                        InfoRow(label: "Est. tokens/sec", value: String(format: "%.1f (estimate)", est))
                    }
                }
            }

            if !run.errorSummaries.isEmpty {
                GroupBox("Errors") {
                    ForEach(run.errorSummaries) { error in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.testName).font(.caption.weight(.semibold))
                            Text("\(error.category.rawValue): \(error.redactedDescription)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !run.policyEventSummaries.isEmpty {
                GroupBox("Expected Policy Events") {
                    Text("Informational. Intentional application policy denials, not runtime failures.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(run.policyEventSummaries) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.testName).font(.caption.weight(.semibold))
                            Text("\(event.kind.rawValue): \(event.redactedSummary)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Button("Copy GitHub Device Report") {
                UIPasteboard.general.string = GitHubDeviceReportExporter.makeMarkdown(from: run)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Run Detail")
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.3fs", value)
    }
}

struct CompareRunsView: View {
    let left: DiagnosticRunRecord
    let right: DiagnosticRunRecord

    private var comparison: RunComparisonResult {
        RunComparator.compare(left: left, right: right)
    }

    var body: some View {
        DiagnosticScrollScreen {
            Text("Comparison is observational only. Do not claim statistical significance.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let warning = comparison.crossDeviceWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            GroupBox("Environment") {
                InfoRow(label: "Left device", value: "\(left.marketingName) (\(left.hardwareIdentifier))")
                InfoRow(label: "Right device", value: "\(right.marketingName) (\(right.hardwareIdentifier))")
                InfoRow(label: "OS/build changed", value: comparison.osBuildChanged ? "yes" : "no")
                InfoRow(label: "Locale changed", value: comparison.localeChanged ? "yes" : "no")
                InfoRow(label: "Region changed", value: comparison.regionChanged ? "yes" : "no")
                InfoRow(label: "Availability changed", value: comparison.availabilityChanged ? "yes" : "no")
                InfoRow(label: "Context size changed", value: comparison.contextSizeChanged ? "yes" : "no")
                InfoRow(label: "Offline L→R", value: "\(OfflineObservationFormatter.deviceReportLabel(for: left)) → \(OfflineObservationFormatter.deviceReportLabel(for: right))")
                InfoRow(label: "Thermal L→R", value: "\(left.thermalState ?? "n/a") → \(right.thermalState ?? "n/a")")
            }

            GroupBox("Suite status changes") {
                if comparison.suiteChanges.isEmpty {
                    Text("No suite status changes.")
                        .font(.caption)
                } else {
                    ForEach(comparison.suiteChanges) { change in
                        Text("\(change.suiteName): \(change.leftOutcome?.displayLabel ?? "—") → \(change.rightOutcome?.displayLabel ?? "—")")
                            .font(.caption)
                    }
                }
                if !comparison.addedFailures.isEmpty {
                    Text("Added failures: \(comparison.addedFailures.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if !comparison.resolvedFailures.isEmpty {
                    Text("Resolved failures: \(comparison.resolvedFailures.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            GroupBox("Metrics") {
                ForEach(comparison.metricDeltas, id: \.label) { delta in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(delta.label).font(.caption.weight(.semibold))
                        Text("\(fmt(delta.left)) → \(fmt(delta.right))  Δ \(fmt(delta.absoluteChange))")
                            .font(.caption2)
                        if delta.percentChangeValid, let pct = delta.percentChange {
                            Text(String(format: "%+.1f%%", pct))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else if delta.left == 0 || delta.left == nil || delta.right == nil {
                            Text("Percent change not applicable")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            GroupBox("Error categories") {
                InfoRow(label: "Left", value: comparison.errorCategoriesLeft.isEmpty ? "none" : comparison.errorCategoriesLeft.joined(separator: ", "))
                InfoRow(label: "Right", value: comparison.errorCategoriesRight.isEmpty ? "none" : comparison.errorCategoriesRight.joined(separator: ", "))
            }
        }
        .navigationTitle("Compare Runs")
    }

    private func fmt(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return String(format: "%.3f", value)
    }
}
