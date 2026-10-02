import SwiftUI

/// Lab keeps the existing diagnostic suites behind one list so the tab bar stays short.
struct LabHomeView: View {
    let service: FoundationModelService
    let store: DiagnosticStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScreenIntro(text: "The AFM3 Score uses a fixed subset of these suites. Lab runs are still available one at a time.")
                }

                Section("Interactive") {
                    NavigationLink {
                        BasicGenerationView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Generate",
                            subtitle: "Prompt, streaming, temperature, and latency",
                            systemImage: "text.bubble"
                        )
                    }
                }

                Section("Suites") {
                    NavigationLink {
                        StructuredOutputView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Structured",
                            subtitle: "Guided @Generable output",
                            systemImage: "list.bullet.rectangle"
                        )
                    }
                    NavigationLink {
                        ToolCallingView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Tools",
                            subtitle: "Read-only tools and side-effect permission",
                            systemImage: "wrench.and.screwdriver"
                        )
                    }
                    NavigationLink {
                        ConversationMemoryView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Memory",
                            subtitle: "Session recall and transcript rehydration",
                            systemImage: "brain"
                        )
                    }
                    NavigationLink {
                        MultilingualView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Languages",
                            subtitle: "Compact generation across five languages",
                            systemImage: "globe"
                        )
                    }
                    NavigationLink {
                        SafetyTestsView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Safety",
                            subtitle: "Observations, not a security certification",
                            systemImage: "shield"
                        )
                    }
                    NavigationLink {
                        ContextWindowView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Context",
                            subtitle: "Long-context recall until a limit error",
                            systemImage: "doc.text.magnifyingglass"
                        )
                    }
                    NavigationLink {
                        ConcurrencyView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Concurrency",
                            subtitle: "Conservative sequential and concurrent probes",
                            systemImage: "arrow.triangle.branch"
                        )
                    }
                }

                Section("Measure") {
                    NavigationLink {
                        BenchmarkView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Benchmark",
                            subtitle: "Three streaming repetitions",
                            systemImage: "speedometer"
                        )
                    }
                    NavigationLink {
                        OfflineVerificationView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Offline",
                            subtitle: "Airplane Mode check, not part of the score",
                            systemImage: "airplane"
                        )
                    }
                }

                Section("Records") {
                    NavigationLink {
                        OverviewView(service: service, store: store)
                    } label: {
                        LabRowLabel(
                            title: "Overview",
                            subtitle: "Device, Availability, and the last run",
                            systemImage: "info.circle"
                        )
                    }
                    NavigationLink {
                        ErrorExplorerView(store: store)
                    } label: {
                        LabRowLabel(
                            title: "Errors",
                            subtitle: "Unexpected errors, separate from policy events",
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                    NavigationLink {
                        ExportView(store: store)
                    } label: {
                        LabRowLabel(
                            title: "Export",
                            subtitle: "Redacted JSON, Markdown, and Device Report",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                }
            }
            .navigationTitle("Lab")
        }
    }
}
