import Foundation

/// Fixed, versioned AFM3 Score suite.
///
/// Suite 1 reuses the existing safe diagnostic suites plus the three-repetition
/// streaming benchmark already stored on `DiagnosticRunRecord`. Offline
/// Verification is intentionally excluded: it needs a manual Airplane Mode
/// setup and is not part of the comparable loop.
///
/// A sub-score of 1000 matches the documented calibration baseline. The number
/// is a local AFM3 Toolbox observation. It is not an Apple score and it is not
/// statistically significant.
enum AFM3ScoreSuite: Sendable {
    nonisolated static let version = 1
    nonisolated static let identifier = "afm3-score-suite-1"
    nonisolated static let referenceScore = 1000
    nonisolated static let minimumScore = 1
    nonisolated static let maximumScore = 10_000

    /// Median total generation time that scores 1000 on Latency.
    nonisolated static let latencyBaselineSeconds = 2.0
    /// Median time to first streamed content that scores 1000 on Responsiveness.
    nonisolated static let responsivenessBaselineSeconds = 0.4
    /// Estimated tokens/sec (~4 characters per token) that scores 1000 on Throughput.
    nonisolated static let throughputBaselineEstimatedTokensPerSecond = 20.0

    nonisolated static let capabilityMembers: [String] = [
        "Structured Output",
        "Conversation Memory",
        "Tool Calling",
        "Multilingual",
        "Safety & Prompt Injection",
        "Context Window",
        "Concurrency & Rate Limit",
    ]

    nonisolated static let benchmarkMember = "Performance Benchmark"

    nonisolated static let honestyNote =
        "AFM3 Scores are comparable only for the same device and the same score suite version."
}

enum AFM3ScoreProvenance: String, Codable, Sendable, Hashable {
    /// Written when the run was saved.
    case stored
    /// Computed later from suite results on an older history record.
    case derived
}

struct AFM3SubScore: Codable, Sendable, Hashable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    /// Nil when this component cannot be scored.
    let value: Int?
    let detail: String
}

struct AFM3ScoreSnapshot: Codable, Sendable, Hashable {
    let suiteIdentifier: String
    let suiteVersion: Int
    /// Geometric mean of the four sub-scores. Nil when the suite is incomplete.
    let composite: Int?
    let isComplete: Bool
    let subScores: [AFM3SubScore]
    let missingMembers: [String]
    let provenance: AFM3ScoreProvenance
}

struct AFM3ToplistEntry: Sendable, Hashable, Identifiable {
    var id: UUID { runID }
    let runID: UUID
    let timestamp: Date
    let marketingName: String
    let hardwareIdentifier: String
    let suiteVersion: Int
    let suiteIdentifier: String
    let composite: Int
    let thermalState: String?
    let isCharging: Bool?
    let isLowPowerModeEnabled: Bool?
    let matchesCurrentDevice: Bool
}

struct AFM3Toplist: Sendable, Hashable {
    let currentSuiteVersion: Int
    /// Complete scores for the current suite version, highest composite first.
    let ranked: [AFM3ToplistEntry]
    /// Complete scores from a different suite version. Not ranked with `ranked`.
    let otherSuiteVersions: [AFM3ToplistEntry]
    let incompleteCount: Int
}

enum AFM3ScoreCalculator: Sendable {

    nonisolated static func resolve(_ run: DiagnosticRunRecord) -> AFM3ScoreSnapshot {
        if let stored = run.afm3Score {
            return stored
        }
        return makeSnapshot(
            suiteResults: run.suiteResults,
            benchmarkSummary: run.benchmarkSummary,
            provenance: .derived
        )
    }

    nonisolated static func makeSnapshot(
        suiteResults: [StoredSuiteResult],
        benchmarkSummary: BenchmarkSummary?,
        provenance: AFM3ScoreProvenance
    ) -> AFM3ScoreSnapshot {
        var outcomes: [String: TestOutcome] = [:]
        for result in suiteResults {
            outcomes[result.suiteName] = result.outcome
        }
        var missing: [String] = []

        let capability = capabilityScore(outcomes: outcomes, missing: &missing)
        let latency = performanceScore(
            key: "latency",
            title: "Latency",
            outcome: outcomes[AFM3ScoreSuite.benchmarkMember],
            metric: benchmarkSummary?.medianTotalLatencySeconds,
            baseline: AFM3ScoreSuite.latencyBaselineSeconds,
            higherIsFaster: true,
            unit: "s median total",
            missing: &missing
        )
        let responsiveness = performanceScore(
            key: "responsiveness",
            title: "Responsiveness",
            outcome: outcomes[AFM3ScoreSuite.benchmarkMember],
            metric: benchmarkSummary?.medianTimeToFirstStreamedContentSeconds,
            baseline: AFM3ScoreSuite.responsivenessBaselineSeconds,
            higherIsFaster: true,
            unit: "s median first streamed content",
            missing: &missing
        )
        let throughput = performanceScore(
            key: "throughput",
            title: "Throughput",
            outcome: outcomes[AFM3ScoreSuite.benchmarkMember],
            metric: benchmarkSummary?.estimatedMedianTokensPerSecond,
            baseline: AFM3ScoreSuite.throughputBaselineEstimatedTokensPerSecond,
            higherIsFaster: false,
            unit: "estimated tokens/sec",
            missing: &missing
        )

        let subscores = [latency, throughput, responsiveness, capability]
        let values = subscores.compactMap(\.value)
        let complete = missing.isEmpty && values.count == subscores.count
        let composite = complete ? geometricMean(of: values) : nil

        return AFM3ScoreSnapshot(
            suiteIdentifier: AFM3ScoreSuite.identifier,
            suiteVersion: AFM3ScoreSuite.version,
            composite: composite,
            isComplete: complete && composite != nil,
            subScores: subscores,
            missingMembers: missing,
            provenance: provenance
        )
    }

    nonisolated static func geometricMean(of values: [Int]) -> Int? {
        guard !values.isEmpty, values.allSatisfy({ $0 > 0 }) else { return nil }
        let meanLog = values.reduce(0.0) { $0 + log(Double($1)) } / Double(values.count)
        let raw = exp(meanLog)
        guard raw.isFinite else { return nil }
        return clamp(Int(raw.rounded()))
    }

    /// Ratio against a positive baseline. `higherIsFaster` inverts the ratio so lower seconds score higher.
    nonisolated static func ratioScore(observed: Double, baseline: Double, higherIsFaster: Bool) -> Int? {
        guard observed > 0, baseline > 0, observed.isFinite, baseline.isFinite else { return nil }
        let ratio = higherIsFaster ? (baseline / observed) : (observed / baseline)
        guard ratio.isFinite else { return nil }
        return clamp(Int((Double(AFM3ScoreSuite.referenceScore) * ratio).rounded()))
    }

    nonisolated static func capabilityCredit(for outcome: TestOutcome) -> Double? {
        switch outcome {
        case .passed, .expectedPolicyBlock, .observation:
            return 1
        case .partial:
            return 0.5
        case .failed:
            return 0
        case .unavailable, .skipped:
            return nil
        }
    }

    nonisolated static func conditionNotes(
        thermalState: String?,
        isCharging: Bool?,
        isLowPowerModeEnabled: Bool?
    ) -> [String] {
        var notes: [String] = []
        if let thermalState {
            let normalized = thermalState.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !normalized.isEmpty, normalized != "nominal", normalized != "n/a", normalized != "unknown" {
                notes.append("Thermal state was \(thermalState). Heat can lower the score.")
            }
        }
        if isCharging == true {
            notes.append("The device was charging. Charging can change sustained performance.")
        }
        if isLowPowerModeEnabled == true {
            notes.append("Low Power Mode was on. Treat the score as a constrained observation.")
        }
        return notes
    }

    nonisolated static func clamp(_ value: Int) -> Int {
        min(AFM3ScoreSuite.maximumScore, max(AFM3ScoreSuite.minimumScore, value))
    }

    private nonisolated static func capabilityScore(
        outcomes: [String: TestOutcome],
        missing: inout [String]
    ) -> AFM3SubScore {
        var credits: [Double] = []
        for name in AFM3ScoreSuite.capabilityMembers {
            guard let outcome = outcomes[name] else {
                missing.append(name)
                continue
            }
            guard let credit = capabilityCredit(for: outcome) else {
                missing.append(name)
                continue
            }
            credits.append(credit)
        }

        let value: Int?
        let detail: String
        if credits.count == AFM3ScoreSuite.capabilityMembers.count {
            let mean = credits.reduce(0, +) / Double(credits.count)
            value = clamp(Int((Double(AFM3ScoreSuite.referenceScore) * mean).rounded()))
            detail = "\(credits.count) suite members scored"
        } else {
            value = nil
            detail = "Waiting for every capability suite"
        }
        return AFM3SubScore(key: "capability", title: "Capability", value: value, detail: detail)
    }

    private nonisolated static func performanceScore(
        key: String,
        title: String,
        outcome: TestOutcome?,
        metric: Double?,
        baseline: Double,
        higherIsFaster: Bool,
        unit: String,
        missing: inout [String]
    ) -> AFM3SubScore {
        let benchmarkReady = outcome == .passed
        if outcome != .passed {
            if !missing.contains(AFM3ScoreSuite.benchmarkMember) {
                missing.append(AFM3ScoreSuite.benchmarkMember)
            }
        }
        guard benchmarkReady, let metric, let value = ratioScore(
            observed: metric,
            baseline: baseline,
            higherIsFaster: higherIsFaster
        ) else {
            if benchmarkReady && !missing.contains(title) {
                missing.append(title)
            }
            return AFM3SubScore(
                key: key,
                title: title,
                value: nil,
                detail: "Needs a passed \(AFM3ScoreSuite.benchmarkMember)"
            )
        }
        return AFM3SubScore(
            key: key,
            title: title,
            value: value,
            detail: String(format: "%.3f %@ (baseline %.3f = 1000)", metric, unit, baseline)
        )
    }
}

enum AFM3ToplistBuilder: Sendable {

    nonisolated static func build(
        runs: [DiagnosticRunRecord],
        currentHardwareIdentifier: String,
        thisDeviceOnly: Bool
    ) -> AFM3Toplist {
        var ranked: [AFM3ToplistEntry] = []
        var other: [AFM3ToplistEntry] = []
        var incomplete = 0

        for run in runs {
            let score = AFM3ScoreCalculator.resolve(run)
            let matches = run.hardwareIdentifier == currentHardwareIdentifier
            if thisDeviceOnly && !matches {
                continue
            }
            guard score.isComplete, let composite = score.composite else {
                incomplete += 1
                continue
            }
            let entry = AFM3ToplistEntry(
                runID: run.id,
                timestamp: run.timestamp,
                marketingName: run.marketingName,
                hardwareIdentifier: run.hardwareIdentifier,
                suiteVersion: score.suiteVersion,
                suiteIdentifier: score.suiteIdentifier,
                composite: composite,
                thermalState: run.thermalState ?? run.benchmarkSummary?.thermalStateAfter,
                isCharging: run.isCharging ?? run.benchmarkSummary?.isCharging,
                isLowPowerModeEnabled: run.isLowPowerModeEnabled ?? run.benchmarkSummary?.isLowPowerModeEnabled,
                matchesCurrentDevice: matches
            )
            if score.suiteVersion == AFM3ScoreSuite.version {
                ranked.append(entry)
            } else {
                other.append(entry)
            }
        }

        ranked.sort(by: sortEntries)
        other.sort(by: sortEntries)
        return AFM3Toplist(
            currentSuiteVersion: AFM3ScoreSuite.version,
            ranked: ranked,
            otherSuiteVersions: other,
            incompleteCount: incomplete
        )
    }

    private nonisolated static func sortEntries(_ lhs: AFM3ToplistEntry, _ rhs: AFM3ToplistEntry) -> Bool {
        if lhs.composite != rhs.composite {
            return lhs.composite > rhs.composite
        }
        return lhs.timestamp > rhs.timestamp
    }
}

enum AFM3ScoreCard: Sendable {

    /// Redacted Markdown score card. Contains no prompts and no model response bodies.
    nonisolated static func makeMarkdown(from run: DiagnosticRunRecord) -> String {
        let score = AFM3ScoreCalculator.resolve(run)
        var lines: [String] = []
        lines.append("# AFM3 Score Card")
        lines.append("")
        lines.append("Local AFM3 Toolbox observation from on-device SystemLanguageModel. Not an official Apple score. Not statistically significant.")
        lines.append("")
        lines.append(AFM3ScoreSuite.honestyNote)
        lines.append("This card stays on device until you paste or share it. AFM3Tester does not upload scores.")
        lines.append("")
        lines.append("| Field | Value |")
        lines.append("| --- | --- |")
        lines.append("| AFM3 Score | \(score.composite.map(String.init) ?? "incomplete") |")
        lines.append("| Complete | \(score.isComplete ? "yes" : "no") |")
        lines.append("| Suite | \(score.suiteIdentifier) (v\(score.suiteVersion)) |")
        lines.append("| Provenance | \(score.provenance.rawValue) |")
        lines.append("| App | \(redact(run.appVersion)) (\(redact(run.appBuild))) |")
        lines.append("| Device | \(redact(run.marketingName)) |")
        lines.append("| Hardware identifier | \(redact(run.hardwareIdentifier)) |")
        lines.append("| OS | \(redact(run.osVersion)) (\(redact(run.osBuild))) |")
        lines.append("| Availability | \(redact(run.availability)) |")
        lines.append("| Deployment | \(redact(run.deploymentObservation)) |")
        lines.append("| Simulator | \(run.isSimulator ? "yes" : "no") |")
        lines.append("")
        lines.append("## Sub-scores")
        lines.append("")
        for sub in score.subScores {
            let value = sub.value.map(String.init) ?? "n/a"
            lines.append("- **\(sub.title):** \(value) — \(redact(sub.detail))")
        }
        lines.append("")
        if !score.missingMembers.isEmpty {
            lines.append("## Missing for a complete score")
            lines.append("")
            for member in score.missingMembers {
                lines.append("- \(redact(member))")
            }
            lines.append("")
        }
        let notes = AFM3ScoreCalculator.conditionNotes(
            thermalState: run.thermalState ?? run.benchmarkSummary?.thermalStateAfter,
            isCharging: run.isCharging ?? run.benchmarkSummary?.isCharging,
            isLowPowerModeEnabled: run.isLowPowerModeEnabled ?? run.benchmarkSummary?.isLowPowerModeEnabled
        )
        lines.append("## Conditions")
        lines.append("")
        lines.append("- Thermal: \(redact(run.thermalState ?? "n/a"))")
        lines.append("- Charging: \(yesNo(run.isCharging))")
        lines.append("- Low Power Mode: \(yesNo(run.isLowPowerModeEnabled))")
        for note in notes {
            lines.append("- \(redact(note))")
        }
        lines.append("")
        lines.append("Expected Policy Events are application policy denials, not score failures.")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private nonisolated static func redact(_ text: String) -> String {
        ReportRedactor.redact(text)
    }

    private nonisolated static func yesNo(_ value: Bool?) -> String {
        switch value {
        case true: "yes"
        case false: "no"
        case nil: "n/a"
        }
    }
}
