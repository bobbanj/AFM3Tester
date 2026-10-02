import SwiftUI

struct ToplistView: View {
    let store: DiagnosticStore

    @State private var thisDeviceOnly = true
    @State private var hardwareIdentifier = DeviceInfoProvider.deviceModelIdentifier

    private var toplist: AFM3Toplist {
        AFM3ToplistBuilder.build(
            runs: store.historyStore.runs,
            currentHardwareIdentifier: hardwareIdentifier,
            thisDeviceOnly: thisDeviceOnly
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScreenIntro(
                        text: "Local toplist from History. Ranks use suite v\(AFM3ScoreSuite.version) only. \(AFM3ScoreSuite.honestyNote)"
                    )
                    Toggle("This device only", isOn: $thisDeviceOnly)
                    if toplist.incompleteCount > 0 {
                        Text("\(toplist.incompleteCount) History run\(toplist.incompleteCount == 1 ? "" : "s") omitted because the AFM3 Score is incomplete.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Suite v\(toplist.currentSuiteVersion)") {
                    if toplist.ranked.isEmpty {
                        EmptyStateView(
                            systemImage: "list.number",
                            title: "No ranked scores",
                            message: thisDeviceOnly
                                ? "Run AFM3 Score on this iPhone. Other devices stay hidden while This device only is on."
                                : "Complete a score suite to appear here. Incomplete runs stay in History."
                        )
                    } else {
                        ForEach(Array(toplist.ranked.enumerated()), id: \.element.id) { index, entry in
                            if let run = store.historyStore.run(id: entry.runID) {
                                NavigationLink {
                                    HistoryDetailView(run: run, store: store)
                                } label: {
                                    ToplistRow(rank: index + 1, entry: entry)
                                }
                            }
                        }
                    }
                }

                if !toplist.otherSuiteVersions.isEmpty {
                    Section("Other suite versions") {
                        Text("These complete scores use a different suite version and are not ranked with the list above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(toplist.otherSuiteVersions) { entry in
                            if let run = store.historyStore.run(id: entry.runID) {
                                NavigationLink {
                                    HistoryDetailView(run: run, store: store)
                                } label: {
                                    ToplistRow(rank: nil, entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Toplist")
            .onAppear {
                hardwareIdentifier = DeviceInfoProvider.deviceModelIdentifier
            }
        }
    }
}

private struct ToplistRow: View {
    let rank: Int?
    let entry: AFM3ToplistEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(rank.map(String.init) ?? "·")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .frame(width: 28, alignment: .leading)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.marketingName)
                    .font(.body.weight(.semibold))
                Text("\(entry.hardwareIdentifier) · suite v\(entry.suiteVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if !entry.matchesCurrentDevice {
                    Text("Different device")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 8)
            Text("\(entry.composite)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
