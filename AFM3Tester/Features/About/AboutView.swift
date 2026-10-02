import FoundationModels
import SwiftUI

struct AboutView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var availability = "Loading…"
    @State private var contextSizeValue: Int?
    @State private var copiedEnvironment = false

    private var appVersion: String {
        AppRelease.marketingVersion
    }

    private var appBuild: String {
        AppRelease.buildNumber
    }

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AFM3 Toolbox")
                        .font(.title.weight(.bold))
                    Text("AFM3Tester")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Version \(appVersion) · Build \(appBuild)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                ScreenIntro(text: "On-device Apple Foundation Models only. No other model providers and no cloud inference.")

                GroupBox("Links") {
                    InfoRow(label: "Repository", value: "https://github.com/bobbanj/AFM3Tester")
                    InfoRow(label: "TestFlight", value: "https://testflight.apple.com/join/FJMVaGWC")
                    InfoRow(label: "License", value: "MIT")
                }

                GroupBox("Privacy") {
                    Text("No analytics")
                    Text("No telemetry")
                    Text("No third-party SDKs")
                    Text("Local toplist only")
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    Button("Open GitHub Repository") {
                        if let url = URL(string: "https://github.com/bobbanj/AFM3Tester") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open TestFlight") {
                        if let url = URL(string: "https://testflight.apple.com/join/FJMVaGWC") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(copiedEnvironment ? "Copied Environment Summary" : "Copy Environment Summary") {
                        UIPasteboard.general.string = store.copyEnvironmentSummary(
                            availability: availability,
                            contextSize: contextSizeValue
                        )
                        copiedEnvironment = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .navigationTitle("About")
            .task { await refresh() }
        }
    }

    private func refresh() async {
        availability = await service.availabilityDescription
        contextSizeValue = await service.contextSize
    }
}
