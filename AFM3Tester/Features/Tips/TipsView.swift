import SwiftUI

struct TipArticle: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let summary: String
    let body: String
}

enum TipsCatalog: Sendable {
    nonisolated static let articles: [TipArticle] = [
        TipArticle(
            id: "airplane-mode",
            title: "Airplane Mode offline check",
            symbol: "airplane",
            summary: "Offline Verification only runs when no network path is satisfied.",
            body: """
            AFM3Tester cannot toggle Airplane Mode. On a physical iPhone, turn Airplane Mode on yourself, then turn Wi-Fi off if it stays connected. Open Lab → Offline and wait until the observed path is not satisfied. Then run Offline Verification.

            A completed offline run should show the same outcome in History and in a Device Report, including check counts. Offline Verification is not part of the AFM3 Score.
            """
        ),
        TipArticle(
            id: "assets-download",
            title: "Assets download",
            symbol: "arrow.down.circle",
            summary: "Apple Intelligence assets have to finish downloading before inference works.",
            body: """
            SystemLanguageModel stays unavailable until the on-device Foundation Models assets are downloaded. On the Score tab, check Availability. If it is not Available, leave the iPhone unlocked and on Wi-Fi until Apple Intelligence finishes the download, then pull to refresh.

            An unavailable model is not a failed score. The suite stays incomplete until the model can run.
            """
        ),
        TipArticle(
            id: "simulator",
            title: "Simulator cannot infer",
            symbol: "iphone.slash",
            summary: "The iOS Simulator can show the UI. It cannot run the model.",
            body: """
            Foundation Models inference is unsupported in Simulator. A typical reflected error is operationNotAllowed with a simulator message. Build the app onto a supported physical iPhone to collect a score, a toplist entry, or a Device Report.

            Simulator builds are still useful for layout and for the XCTest target.
            """
        ),
        TipArticle(
            id: "expected-policy-event",
            title: "Expected Policy Event is not a failure",
            symbol: "checkmark.shield",
            summary: "A denied side effect means the app policy held.",
            body: """
            Tool Calling asks the model to use setDemoTheme without permission. The app is supposed to deny that call. History, Errors, and the score record that denial as an Expected Policy Event, not as an Error and not as a failed suite.

            Quoted text in a prompt does not grant permission. Turn on Allow side-effect tools only when you intend to test the authorized path. That permission is never implied by model output.
            """
        ),
        TipArticle(
            id: "thermal-charging",
            title: "Thermal state and charging",
            symbol: "thermometer.medium",
            summary: "Heat, charging, and Low Power Mode change latency.",
            body: """
            The benchmark records thermal state, battery, charging, and Low Power Mode around the three streaming repetitions. A warm device or Low Power Mode can make Latency, Responsiveness, and Throughput look worse. Charging can change sustained performance as well.

            The score card repeats those conditions. Compare runs on the same device, with the same suite version, and with similar thermals before you treat a percent change as meaningful. The comparison is still an observation, not a statistically significant result.
            """
        ),
        TipArticle(
            id: "device-report",
            title: "Device Report paste flow",
            symbol: "doc.on.clipboard",
            summary: "Copy the redacted report, then paste it into a GitHub issue.",
            body: """
            After a physical-device run, use Copy GitHub Device Report from Lab → Overview, Lab → Export, or History. Paste that Markdown into a Community Device Report issue. Use Copy Score Card when you only want the AFM3 Score, sub-scores, and conditions.

            Both texts are redacted locally. They omit prompts. Read them before you publish. The toplist is not uploaded.
            """
        ),
    ]

    nonisolated static func article(id: String) -> TipArticle? {
        articles.first { $0.id == id }
    }
}

struct TipsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScreenIntro(text: "Short notes for running AFM3Tester on a physical iPhone. Nothing here is downloaded.")
                }
                Section("Tips & tricks") {
                    ForEach(TipsCatalog.articles) { article in
                        NavigationLink {
                            TipDetailView(article: article)
                        } label: {
                            LabRowLabel(
                                title: article.title,
                                subtitle: article.summary,
                                systemImage: article.symbol
                            )
                        }
                    }
                }
            }
            .navigationTitle("Tips")
        }
    }
}

struct TipDetailView: View {
    let article: TipArticle

    var body: some View {
        DiagnosticScrollScreen {
            Label(article.title, systemImage: article.symbol)
                .font(.title2.weight(.semibold))
            Text(article.body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
