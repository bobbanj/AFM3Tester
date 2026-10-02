import Foundation

struct SuiteStatusChange: Codable, Sendable, Hashable, Identifiable {
    var id: String { suiteName }
    let suiteName: String
    let leftOutcome: TestOutcome?
    let rightOutcome: TestOutcome?
}

struct MetricDelta: Codable, Sendable, Hashable {
    let label: String
    let left: Double?
    let right: Double?
    let absoluteChange: Double?
    let percentChange: Double?
    let percentChangeValid: Bool
}

struct RunComparisonResult: Codable, Sendable, Hashable {
    let leftID: UUID
    let rightID: UUID
    let osBuildChanged: Bool
    let deviceChanged: Bool
    let localeChanged: Bool
    let regionChanged: Bool
    let availabilityChanged: Bool
    let contextSizeChanged: Bool
    let leftHardwareIdentifier: String
    let rightHardwareIdentifier: String
    let crossDeviceWarning: String?
    let suiteChanges: [SuiteStatusChange]
    let addedFailures: [String]
    let resolvedFailures: [String]
    let metricDeltas: [MetricDelta]
    let offlineLeft: TestOutcome?
    let offlineRight: TestOutcome?
    let thermalLeft: String?
    let thermalRight: String?
    let errorCategoriesLeft: [String]
    let errorCategoriesRight: [String]
    let leftSuiteVersion: Int?
    let rightSuiteVersion: Int?
    let leftCompositeScore: Int?
    let rightCompositeScore: Int?
    let sameSuiteVersion: Bool
    /// True only when both scores are complete, the hardware matches, and the suite version matches.
    let scoresComparable: Bool
    let scoreHonestyNote: String
}

enum RunComparator: Sendable {

    /// Percentage change only when the baseline is non-zero and both values exist.
    nonisolated static func percentChange(from left: Double?, to right: Double?) -> (Double?, Bool) {
        guard let left, let right else { return (nil, false) }
        guard left != 0 else { return (nil, false) }
        return (((right - left) / left) * 100.0, true)
    }

    nonisolated static func absoluteChange(from left: Double?, to right: Double?) -> Double? {
        guard let left, let right else { return nil }
        return right - left
    }

    nonisolated static func compare(left: DiagnosticRunRecord, right: DiagnosticRunRecord) -> RunComparisonResult {
        let deviceChanged = left.hardwareIdentifier != right.hardwareIdentifier
        let crossDeviceWarning: String? = deviceChanged
            ? "Performance percentages across different device models are not comparable. Absolute values are shown; treat percent deltas with caution."
            : nil

        let leftSuites = Dictionary(uniqueKeysWithValues: left.suiteResults.map { ($0.suiteName, $0) })
        let rightSuites = Dictionary(uniqueKeysWithValues: right.suiteResults.map { ($0.suiteName, $0) })
        let allNames = Set(leftSuites.keys).union(rightSuites.keys).sorted()

        var suiteChanges: [SuiteStatusChange] = []
        var addedFailures: [String] = []
        var resolvedFailures: [String] = []

        for name in allNames {
            let l = leftSuites[name]?.outcome
            let r = rightSuites[name]?.outcome
            if l != r {
                suiteChanges.append(SuiteStatusChange(suiteName: name, leftOutcome: l, rightOutcome: r))
            }
            if l != .failed && r == .failed {
                addedFailures.append(name)
            }
            if l == .failed && r != .failed {
                resolvedFailures.append(name)
            }
        }

        func metric(_ label: String, _ l: Double?, _ r: Double?) -> MetricDelta {
            let (pct, valid) = percentChange(from: l, to: r)
            return MetricDelta(
                label: label,
                left: l,
                right: r,
                absoluteChange: absoluteChange(from: l, to: r),
                percentChange: pct,
                percentChangeValid: valid && !deviceChanged
            )
        }

        let leftTotals = left.suiteResults.compactMap(\.totalLatencySeconds)
        let rightTotals = right.suiteResults.compactMap(\.totalLatencySeconds)
        let leftTTFT = left.suiteResults.compactMap(\.timeToFirstStreamedContentSeconds)
        let rightTTFT = right.suiteResults.compactMap(\.timeToFirstStreamedContentSeconds)

        var deltas: [MetricDelta] = [
            metric("Total latency (sum of suite totals)", leftTotals.reduce(0, +), rightTotals.reduce(0, +)),
            metric(
                "Median time to first streamed content",
                BenchmarkStatistics.median(of: leftTTFT),
                BenchmarkStatistics.median(of: rightTTFT)
            ),
            metric(
                "Benchmark median total latency",
                left.benchmarkSummary?.medianTotalLatencySeconds,
                right.benchmarkSummary?.medianTotalLatencySeconds
            ),
            metric(
                "Benchmark min total latency",
                left.benchmarkSummary?.minTotalLatencySeconds,
                right.benchmarkSummary?.minTotalLatencySeconds
            ),
            metric(
                "Benchmark max total latency",
                left.benchmarkSummary?.maxTotalLatencySeconds,
                right.benchmarkSummary?.maxTotalLatencySeconds
            ),
        ]

        if let lc = left.contextSize, let rc = right.contextSize {
            deltas.append(metric("Context size", Double(lc), Double(rc)))
        }

        let leftScore = AFM3ScoreCalculator.resolve(left)
        let rightScore = AFM3ScoreCalculator.resolve(right)
        let sameSuite = leftScore.suiteVersion == rightScore.suiteVersion
        let scoresComparable = !deviceChanged
            && sameSuite
            && leftScore.isComplete
            && rightScore.isComplete
            && leftScore.composite != nil
            && rightScore.composite != nil
        let honesty = scoreHonestyNote(
            deviceChanged: deviceChanged,
            sameSuiteVersion: sameSuite,
            scoresComparable: scoresComparable
        )
        let (scorePercent, scorePercentValid) = percentChange(
            from: leftScore.composite.map(Double.init),
            to: rightScore.composite.map(Double.init)
        )
        deltas.append(
            MetricDelta(
                label: "AFM3 Score",
                left: leftScore.composite.map(Double.init),
                right: rightScore.composite.map(Double.init),
                absoluteChange: absoluteChange(
                    from: leftScore.composite.map(Double.init),
                    to: rightScore.composite.map(Double.init)
                ),
                percentChange: scorePercent,
                percentChangeValid: scorePercentValid && scoresComparable
            )
        )

        return RunComparisonResult(
            leftID: left.id,
            rightID: right.id,
            osBuildChanged: left.osBuild != right.osBuild || left.osVersion != right.osVersion,
            deviceChanged: deviceChanged,
            localeChanged: left.localeIdentifier != right.localeIdentifier,
            regionChanged: left.regionCode != right.regionCode,
            availabilityChanged: left.availability != right.availability,
            contextSizeChanged: left.contextSize != right.contextSize,
            leftHardwareIdentifier: left.hardwareIdentifier,
            rightHardwareIdentifier: right.hardwareIdentifier,
            crossDeviceWarning: crossDeviceWarning,
            suiteChanges: suiteChanges,
            addedFailures: addedFailures,
            resolvedFailures: resolvedFailures,
            metricDeltas: deltas,
            offlineLeft: left.offlineOutcome,
            offlineRight: right.offlineOutcome,
            thermalLeft: left.thermalState,
            thermalRight: right.thermalState,
            errorCategoriesLeft: left.errorSummaries.map(\.category.rawValue).sorted(),
            errorCategoriesRight: right.errorSummaries.map(\.category.rawValue).sorted(),
            leftSuiteVersion: leftScore.suiteVersion,
            rightSuiteVersion: rightScore.suiteVersion,
            leftCompositeScore: leftScore.composite,
            rightCompositeScore: rightScore.composite,
            sameSuiteVersion: sameSuite,
            scoresComparable: scoresComparable,
            scoreHonestyNote: honesty
        )
    }

    nonisolated static func scoreHonestyNote(
        deviceChanged: Bool,
        sameSuiteVersion: Bool,
        scoresComparable: Bool
    ) -> String {
        if scoresComparable {
            return "Same device and same AFM3 Score suite version. The composite percent change is an observation, not a statistically significant result."
        }
        if deviceChanged && !sameSuiteVersion {
            return "Different device and different AFM3 Score suite version. Do not compare these composite scores."
        }
        if deviceChanged {
            return "Different device. AFM3 Scores are not ranked against each other across hardware."
        }
        if !sameSuiteVersion {
            return "Different AFM3 Score suite version. Composite numbers from different suites are not the same benchmark."
        }
        return "AFM3 Score is incomplete on at least one run, so the composite numbers are not compared."
    }
}
