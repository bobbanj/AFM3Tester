import SwiftUI

enum ToolboxTab: Hashable {
    case score
    case toplist
    case lab
    case history
    case tips
    case about
}

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
    @State private var tab = ToolboxTab.score

    var body: some View {
        TabView(selection: $tab) {
            ScoreHomeView(service: service, store: store) {
                tab = .history
            }
            .tabItem { Label("Score", systemImage: "gauge.with.dots.needle.67percent") }
            .tag(ToolboxTab.score)

            ToplistView(store: store)
                .tabItem { Label("Toplist", systemImage: "list.number") }
                .tag(ToolboxTab.toplist)

            LabHomeView(service: service, store: store)
                .tabItem { Label("Lab", systemImage: "flask") }
                .tag(ToolboxTab.lab)

            HistoryListView(store: store)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(ToolboxTab.history)

            TipsView()
                .tabItem { Label("Tips", systemImage: "lightbulb") }
                .tag(ToolboxTab.tips)

            AboutView(service: service, store: store)
                .tabItem { Label("About", systemImage: "questionmark.circle") }
                .tag(ToolboxTab.about)
        }
        .preferredColorScheme(store.demoTheme)
    }
}
