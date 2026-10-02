import SwiftUI

struct ScoreHomeView: View {
    let service: FoundationModelService
    let store: DiagnosticStore
    var onOpenHistory: () -> Void

    @State private var availability = "Loading…"
    @State private var copiedCard = false
    @State private var snapshot = DeviceInfoProvider.captureSnapshot()

    private var latestRun: DiagnosticRunRecord? {
        store.historyStore.runs.first
    }

    private var score: AFM3ScoreSnapshot? {
        latestRun.map(AFM3ScoreCalculator.resolve)
    }

    var body: some View {
        NavigationStack {
            DiagnosticScrollScreen {
                ScoreHeroView(
                    score: score?.isComplete == true ? score?.composite : nil,
                    caption: heroCaption
                )

                if let score {
                    GroupBox("Sub-scores") {
                        ForEach(score.subScores) { sub in
                            SubScoreRow(title: sub.title, value: sub.value, detail: sub.detail)
                        }
                    }
                    Text("1000 matches the AFM3 Toolbox calibration baseline for suite \(AFM3ScoreSuite.identifier).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let run = latestRun {
                    let notes = AFM3ScoreCalculator.conditionNotes(
                        thermalState: run.thermalState,
                        isCharging: run.isCharging,
                        isLowPowerModeEnabled: run.isLowPowerModeEnabled
                    )
                    if !notes.isEmpty {
                        GroupBox("Conditions") {
                            ForEach(notes, id: \.self) { note in
                                Label(note, systemImage: "thermometer.medium")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        systemImage: "gauge.with.dots.needle.67percent",
                        title: "No local score yet",
                        message: "Run the fixed suite on a physical iPhone. The composite is saved in History on this device."
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    RunTestButton(
                        title: store.isRunningAllSafeTests ? "Running suite…" : "Run AFM3 Score",
                        isRunning: store.isRunningAllSafeTests || store.isInferenceBusy
                    ) {
                        Task { await runSuite() }
                    }

                    Button(copiedCard ? "Copied Score Card" : "Copy Score Card") {
                        guard let run = latestRun else { return }
                        UIPasteboard.general.string = AFM3ScoreCard.makeMarkdown(from: run)
                        copiedCard = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(latestRun == nil)

                    Button("Compare Runs in History") {
                        onOpenHistory()
                    }
                    .buttonStyle(.bordered)
                }

                GroupBox("This run") {
                    InfoRow(label: "Device", value: snapshot.marketingName)
                    InfoRow(label: "Hardware ID", value: snapshot.deviceModel)
                    InfoRow(label: "Availability", value: availability)
                    InfoRow(label: "Deployment", value: FoundationModelService.deployment)
                    InfoRow(label: "Suite", value: "\(AFM3ScoreSuite.identifier) v\(AFM3ScoreSuite.version)")
                    if let score, !score.isComplete, !score.missingMembers.isEmpty {
                        InfoRow(label: "Still needed", value: score.missingMembers.joined(separator: ", "))
                    }
                }

                ScreenIntro(text: AFM3ScoreSuite.honestyNote + " The toplist is stored locally and is not uploaded.")

                if snapshot.isSimulator {
                    Label(
                        "Simulator can show this screen, but it cannot run Foundation Models inference.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Score")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private var heroCaption: String {
        guard let score else {
            return "On-device SystemLanguageModel only. Local observation, not an official Apple score."
        }
        if score.isComplete {
            return "Suite v\(score.suiteVersion) · \(score.provenance == .stored ? "Saved with this run" : "Derived from History"). Not an official Apple score."
        }
        return "Incomplete suite v\(score.suiteVersion). Sub-scores appear when each part finishes."
    }

    private func runSuite() async {
        copiedCard = false
        await store.runAllSafeTests(service: service)
        await refresh()
    }

    private func refresh() async {
        snapshot = DeviceInfoProvider.captureSnapshot()
        availability = await service.availabilityDescription
    }
}
