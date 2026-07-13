import SwiftUI

struct MainTabView: View {
    @State private var store = DiagnosticStore.shared
    @State private var service = FoundationModelService(
        diagnosticRecorder: DiagnosticStore.shared,
        recordSuccessfulInference: {
            await MainActor.run {
                DiagnosticStore.shared.markSuccessfulInference()
            }
        }
    )

    var body: some View {
        TabView {
            OverviewView(service: service, store: store)
                .tabItem { Label("Overview", systemImage: "info.circle") }

            BasicGenerationView(service: service, store: store)
                .tabItem { Label("Generate", systemImage: "text.bubble") }

            StructuredOutputView(service: service, store: store)
                .tabItem { Label("Structured", systemImage: "list.bullet.rectangle") }

            ToolCallingView(service: service, store: store)
                .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver") }

            ConversationMemoryView(service: service, store: store)
                .tabItem { Label("Memory", systemImage: "brain") }

            MultilingualView(service: service, store: store)
                .tabItem { Label("Languages", systemImage: "globe") }

            SafetyTestsView(service: service, store: store)
                .tabItem { Label("Safety", systemImage: "shield") }

            ContextWindowView(service: service, store: store)
                .tabItem { Label("Context", systemImage: "doc.text.magnifyingglass") }

            ConcurrencyView(service: service, store: store)
                .tabItem { Label("Concurrency", systemImage: "arrow.triangle.branch") }

            BenchmarkView(service: service, store: store)
                .tabItem { Label("Benchmark", systemImage: "gauge.with.dots.needle.67percent") }

            OfflineVerificationView(service: service, store: store)
                .tabItem { Label("Offline", systemImage: "airplane") }

            ErrorExplorerView(store: store)
                .tabItem { Label("Errors", systemImage: "exclamationmark.triangle") }

            ExportView(store: store)
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
        }
        .preferredColorScheme(store.demoTheme)
    }
}
