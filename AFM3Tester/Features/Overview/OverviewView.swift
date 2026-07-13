import SwiftUI

struct OverviewView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var snapshot = DeviceInfoProvider.captureSnapshot()
    @State private var availability = "Loading…"
    @State private var contextSize = "Loading…"
    @State private var assetsReady = "Unknown"
    @State private var isRunningAll = false

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                GroupBox("Device & OS") {
                    InfoRow(label: "OS Version", value: snapshot.osVersion)
                    InfoRow(label: "OS Build", value: snapshot.osBuild)
                    InfoRow(label: "Device Model", value: snapshot.deviceModel)
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

                if snapshot.isSimulator {
                    Label(
                        "The iOS Simulator does not support on-device Foundation Models inference. Use a physical iPhone with Apple Intelligence enabled.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }

                HStack {
                    Button("Copy Diagnostic Report") {
                        UIPasteboard.general.string = store.copyDiagnosticReport()
                    }
                    .buttonStyle(.bordered)

                    RunTestButton(title: isRunningAll ? "Running…" : "Run All Safe Tests", isRunning: isRunningAll) {
                        Task {
                            isRunningAll = true
                            await store.runAllSafeTests(service: service)
                            isRunningAll = false
                            await refresh()
                        }
                    }
                }

                if !store.testResults.isEmpty {
                    GroupBox("Recent Test Results") {
                        ForEach(Array(store.testResults.values).sorted { $0.recordedAt > $1.recordedAt }.prefix(5)) { result in
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
        contextSize = ModelMetadataFormatter.contextSizeLabel(from: size)
        let available = await service.isModelAvailable
        assetsReady = available ? "Yes (model.isAvailable == true)" : "No"
    }
}
