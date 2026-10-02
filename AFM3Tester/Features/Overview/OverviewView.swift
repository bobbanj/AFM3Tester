import SwiftUI

struct OverviewView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var snapshot = DeviceInfoProvider.captureSnapshot()
    @State private var availability = "Loading…"
    @State private var contextSize = "Loading…"
    @State private var contextSizeValue: Int?
    @State private var assetsReady = "Unknown"
    @State private var isRunningAll = false
    @State private var copiedGitHubReport = false

    var body: some View {
        Group {
            DiagnosticScrollScreen {
                ScreenIntro(text: "Device and Foundation Models state for this iPhone. Run the comparable loop from the Score tab.")

                GroupBox("Device & OS") {
                    InfoRow(label: "Marketing name", value: snapshot.marketingName)
                    InfoRow(label: "Hardware ID", value: snapshot.deviceModel)
                    InfoRow(label: "OS Version", value: snapshot.osVersion)
                    InfoRow(label: "OS Build", value: snapshot.osBuild)
                    InfoRow(label: "Locale", value: snapshot.localeIdentifier)
                    InfoRow(label: "Language", value: snapshot.languageCode)
                    InfoRow(label: "Region", value: snapshot.regionCode)
                    InfoRow(label: "Simulator", value: snapshot.isSimulator ? "Yes" : "No")
                }

                GroupBox("Foundation Models") {
                    InfoRow(label: "Availability", value: availability)
                    InfoRow(label: "Model", value: FoundationModelService.modelName)
                    InfoRow(label: "Deployment", value: FoundationModelService.deployment)
                    InfoRow(label: "Context Window", value: contextSize)
                    InfoRow(label: "Assets Ready", value: assetsReady)
                    InfoRow(
                        label: "Last Success",
                        value: store.lastSuccessfulInference.map {
                            $0.formatted(date: .abbreviated, time: .standard)
                        } ?? "None recorded"
                    )
                }

                if let overall = store.lastOverallStatus {
                    GroupBox("Last Run Summary") {
                        HStack {
                            Text(store.lastOverallSummary ?? overall.displayLabel)
                                .font(.subheadline)
                            Spacer()
                            OverallStatusBadge(status: overall)
                        }
                        Text("Passed / partial / expected policy block / failed / unavailable / skipped are distinct. Expected policy blocks and partial verification do not fail the overall run as hard failures.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if snapshot.isSimulator {
                    Label(
                        "The iOS Simulator does not support on-device Foundation Models inference. Use a physical iPhone with Apple Intelligence enabled.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    RunTestButton(title: isRunningAll ? "Running…" : "Run All Safe Tests", isRunning: isRunningAll || store.isInferenceBusy) {
                        Task {
                            isRunningAll = true
                            await store.runAllSafeTests(service: service)
                            isRunningAll = false
                            await refresh()
                        }
                    }

                    HStack {
                        Button("Copy Diagnostic Report") {
                            UIPasteboard.general.string = store.copyDiagnosticReport()
                        }
                        .buttonStyle(.bordered)

                        Button(copiedGitHubReport ? "Copied" : "Copy GitHub Device Report") {
                            UIPasteboard.general.string = store.copyGitHubDeviceReport(
                                availability: availability,
                                contextSize: contextSizeValue
                            )
                            copiedGitHubReport = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if !store.testResults.isEmpty {
                    GroupBox("Recent Test Results") {
                        ForEach(Array(store.testResults.values).sorted { $0.recordedAt > $1.recordedAt }.prefix(8)) { result in
                            TestResultCard(result: result)
                        }
                    }
                }
                #if DEBUG
                UnitTestDebugView(store: store)
                #endif
            }
            .navigationTitle("Overview")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private func refresh() async {
        snapshot = DeviceInfoProvider.captureSnapshot()
        availability = await service.availabilityDescription
        let size = await service.contextSize
        contextSizeValue = size
        contextSize = ModelMetadataFormatter.contextSizeLabel(from: size)
        let available = await service.isModelAvailable
        assetsReady = available ? "Yes (model.isAvailable == true)" : "No"
    }
}
