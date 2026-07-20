import FoundationModels
import SwiftUI

struct AboutView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    @State private var availability = "Loading…"
    @State private var contextSizeValue: Int?
    @State private var copiedEnvironment = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.2"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "4"
    }

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AFM3Tester")
                        .font(.title.weight(.bold))
                    Text("Version \(appVersion)")
                        .font(.subheadline)
                    Text("Build \(appBuild)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GroupBox("Links") {
                    InfoRow(label: "Repository", value: "https://github.com/bobbanj/AFM3Tester")
                    InfoRow(label: "TestFlight", value: "https://testflight.apple.com/join/FJMVaGWC")
                    InfoRow(label: "License", value: "MIT")
                }

                GroupBox("Privacy") {
                    Text("No analytics")
                    Text("No telemetry")
                    Text("No third-party SDKs")
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
