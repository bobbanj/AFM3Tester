import XCTest
@testable import AFM3Tester

@MainActor
final class AFM3ScoreTests: XCTestCase {
    func testCalibrationBaselinesScoreOneThousand() {
        let run = makeRun()
        let score = AFM3ScoreCalculator.makeSnapshot(
            suiteResults: run.suiteResults,
            benchmarkSummary: run.benchmarkSummary,
            provenance: .stored
        )
        XCTAssertTrue(score.isComplete)
        XCTAssertEqual(score.suiteVersion, AFM3ScoreSuite.version)
        XCTAssertEqual(score.suiteIdentifier, AFM3ScoreSuite.identifier)
        XCTAssertEqual(score.composite, 1000)
        XCTAssertEqual(subscore(score, "latency"), 1000)
        XCTAssertEqual(subscore(score, "throughput"), 1000)
        XCTAssertEqual(subscore(score, "responsiveness"), 1000)
        XCTAssertEqual(subscore(score, "capability"), 1000)
    }

    func testFasterLatencyAndHigherThroughputRaiseSubScores() {
        XCTAssertEqual(
            AFM3ScoreCalculator.ratioScore(observed: 1.0, baseline: 2.0, higherIsFaster: true),
            2000
        )
        XCTAssertEqual(
            AFM3ScoreCalculator.ratioScore(observed: 40, baseline: 20, higherIsFaster: false),
            2000
        )
        XCTAssertNil(AFM3ScoreCalculator.ratioScore(observed: 0, baseline: 2, higherIsFaster: true))
        XCTAssertEqual(AFM3ScoreCalculator.geometricMean(of: [1000, 1000, 1000, 1000]), 1000)
        XCTAssertEqual(AFM3ScoreCalculator.clamp(0), AFM3ScoreSuite.minimumScore)
        XCTAssertEqual(AFM3ScoreCalculator.clamp(99_999), AFM3ScoreSuite.maximumScore)
    }

    func testExpectedPolicyAndObservationCountAsFullCapabilityCredit() {
        let run = makeRun(toolOutcome: .expectedPolicyBlock, safetyOutcome: .observation)
        let score = AFM3ScoreCalculator.resolve(run)
        XCTAssertEqual(subscore(score, "capability"), 1000)
        XCTAssertTrue(score.isComplete)
        XCTAssertEqual(score.provenance, .derived)
    }

    func testFailedCapabilityMemberLowersScoreWithoutDroppingTheSuite() {
        let run = makeRun(toolOutcome: .failed)
        let score = AFM3ScoreCalculator.resolve(run)
        XCTAssertTrue(score.isComplete)
        XCTAssertEqual(subscore(score, "capability"), 857)
        XCTAssertLessThan(score.composite ?? 0, 1000)
    }

    func testUnavailableMemberLeavesScoreIncomplete() {
        let run = makeRun(toolOutcome: .unavailable)
        let score = AFM3ScoreCalculator.resolve(run)
        XCTAssertFalse(score.isComplete)
        XCTAssertNil(score.composite)
        XCTAssertTrue(score.missingMembers.contains("Tool Calling"))
    }

    func testSkippedBenchmarkIsIncomplete() {
        let run = makeRun(benchmarkOutcome: .skipped)
        let score = AFM3ScoreCalculator.resolve(run)
        XCTAssertFalse(score.isComplete)
        XCTAssertTrue(score.missingMembers.contains(AFM3ScoreSuite.benchmarkMember))
    }

    func testStoredScoreIsNotRecomputed() {
        let stored = AFM3ScoreSnapshot(
            suiteIdentifier: "afm3-score-suite-9",
            suiteVersion: 9,
            composite: 4242,
            isComplete: true,
            subScores: [],
            missingMembers: [],
            provenance: .stored
        )
        let run = makeRun(afm3Score: stored)
        let resolved = AFM3ScoreCalculator.resolve(run)
        XCTAssertEqual(resolved.composite, 4242)
        XCTAssertEqual(resolved.suiteVersion, 9)
    }

    func testLegacyRecordWithoutScoreDecodesAndDerives() throws {
        let run = makeRun()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var object = try JSONSerialization.jsonObject(with: encoder.encode(run)) as! [String: Any]
        object.removeValue(forKey: "afm3Score")
        object["schemaVersion"] = 3
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticRunRecord.self, from: data)
        XCTAssertNil(decoded.afm3Score)
        XCTAssertEqual(decoded.schemaVersion, 3)
        let derived = AFM3ScoreCalculator.resolve(decoded)
        XCTAssertEqual(derived.provenance, .derived)
        XCTAssertEqual(derived.composite, 1000)
    }

    func testToplistRanksCurrentSuiteAndSeparatesOtherVersions() {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_000_100)
        let high = makeRun(hardware: "iPhone18,2", timestamp: older, medianLatency: 1.0)
        let low = makeRun(hardware: "iPhone18,2", timestamp: newer, medianLatency: 4.0)
        let otherDevice = makeRun(hardware: "iPhone17,1", timestamp: newer, medianLatency: 1.0)
        let foreign = makeRun(
            hardware: "iPhone18,2",
            timestamp: newer,
            afm3Score: AFM3ScoreSnapshot(
                suiteIdentifier: "afm3-score-suite-2",
                suiteVersion: 2,
                composite: 5000,
                isComplete: true,
                subScores: [],
                missingMembers: [],
                provenance: .stored
            )
        )
        let incomplete = makeRun(hardware: "iPhone18,2", benchmarkOutcome: .skipped)

        let filtered = AFM3ToplistBuilder.build(
            runs: [low, high, otherDevice, foreign, incomplete],
            currentHardwareIdentifier: "iPhone18,2",
            thisDeviceOnly: true
        )
        XCTAssertEqual(filtered.ranked.map(\.runID), [high.id, low.id])
        XCTAssertEqual(filtered.otherSuiteVersions.map(\.runID), [foreign.id])
        XCTAssertEqual(filtered.incompleteCount, 1)
        XCTAssertTrue(filtered.ranked.allSatisfy(\.matchesCurrentDevice))

        let slowerOtherDevice = makeRun(hardware: "iPhone17,1", timestamp: newer, medianLatency: 4)
        let allDevices = AFM3ToplistBuilder.build(
            runs: [high, slowerOtherDevice],
            currentHardwareIdentifier: "iPhone18,2",
            thisDeviceOnly: false
        )
        XCTAssertEqual(allDevices.ranked.map(\.hardwareIdentifier), ["iPhone18,2", "iPhone17,1"])
        XCTAssertFalse(allDevices.ranked[1].matchesCurrentDevice)
    }

    func testScoreCardIsRedactedAndOmitsPrompts() {
        var run = makeRun(availability: "Available user@example.com")
        run = DiagnosticRunRecord(
            id: run.id,
            timestamp: run.timestamp,
            appVersion: run.appVersion,
            appBuild: run.appBuild,
            osVersion: run.osVersion,
            osBuild: run.osBuild,
            hardwareIdentifier: run.hardwareIdentifier,
            marketingName: run.marketingName,
            localeIdentifier: run.localeIdentifier,
            languageCode: run.languageCode,
            regionCode: run.regionCode,
            modelAPIIdentifier: run.modelAPIIdentifier,
            availability: "Available user@example.com",
            deploymentObservation: run.deploymentObservation,
            contextSize: run.contextSize,
            overallStatus: run.overallStatus,
            overallSummary: "Write a three-line haiku about Swift concurrency.",
            suiteResults: run.suiteResults,
            benchmarkSummary: run.benchmarkSummary,
            thermalState: "serious",
            batteryPercentage: run.batteryPercentage,
            isCharging: true,
            isLowPowerModeEnabled: true,
            offlinePathObserved: run.offlinePathObserved,
            offlineOutcome: run.offlineOutcome,
            errorSummaries: run.errorSummaries,
            policyEventSummaries: run.policyEventSummaries,
            isSimulator: false,
            afm3Score: run.afm3Score
        )
        let markdown = AFM3ScoreCard.makeMarkdown(from: run)
        XCTAssertTrue(markdown.contains("# AFM3 Score Card"))
        XCTAssertTrue(markdown.contains("| AFM3 Score | 1000 |"))
        XCTAssertTrue(markdown.contains(AFM3ScoreSuite.identifier))
        XCTAssertTrue(markdown.contains("same device"))
        XCTAssertTrue(markdown.contains("Not an official Apple score"))
        XCTAssertTrue(markdown.contains("[REDACTED_EMAIL]"))
        XCTAssertFalse(markdown.contains("user@example.com"))
        XCTAssertFalse(markdown.lowercased().contains("haiku"))
        XCTAssertFalse(markdown.lowercased().contains("prompt:"))
        XCTAssertTrue(markdown.contains("Thermal state was serious"))
        XCTAssertTrue(markdown.contains("charging"))
        XCTAssertTrue(markdown.contains("Low Power Mode"))
        XCTAssertTrue(markdown.contains("Expected Policy Events"))
    }

    func testSameDeviceSameSuiteScoresAreComparable() {
        let left = makeRun(hardware: "iPhone18,2", medianLatency: 2)
        let right = makeRun(hardware: "iPhone18,2", medianLatency: 1)
        let comparison = RunComparator.compare(left: left, right: right)
        XCTAssertTrue(comparison.scoresComparable)
        XCTAssertTrue(comparison.sameSuiteVersion)
        XCTAssertFalse(comparison.deviceChanged)
        let delta = comparison.metricDeltas.first { $0.label == "AFM3 Score" }
        XCTAssertEqual(delta?.percentChangeValid, true)
        XCTAssertTrue(comparison.scoreHonestyNote.contains("Same device"))
    }

    func testDifferentDeviceOrSuiteVersionIsNotComparable() {
        let left = makeRun(hardware: "iPhone18,2")
        let otherDevice = makeRun(hardware: "iPhone17,1")
        let deviceComparison = RunComparator.compare(left: left, right: otherDevice)
        XCTAssertFalse(deviceComparison.scoresComparable)
        XCTAssertTrue(deviceComparison.scoreHonestyNote.contains("Different device"))
        let scoreDelta = deviceComparison.metricDeltas.first { $0.label == "AFM3 Score" }
        XCTAssertEqual(scoreDelta?.percentChangeValid, false)

        let otherSuite = makeRun(
            hardware: "iPhone18,2",
            afm3Score: AFM3ScoreSnapshot(
                suiteIdentifier: "afm3-score-suite-2",
                suiteVersion: 2,
                composite: 1500,
                isComplete: true,
                subScores: [],
                missingMembers: [],
                provenance: .stored
            )
        )
        let suiteComparison = RunComparator.compare(left: left, right: otherSuite)
        XCTAssertFalse(suiteComparison.scoresComparable)
        XCTAssertFalse(suiteComparison.sameSuiteVersion)
        XCTAssertTrue(suiteComparison.scoreHonestyNote.contains("suite version"))
    }

    func testTipsCoverTheRequiredTopics() {
        let ids = Set(TipsCatalog.articles.map(\.id))
        XCTAssertEqual(
            ids,
            [
                "airplane-mode",
                "assets-download",
                "simulator",
                "expected-policy-event",
                "thermal-charging",
                "device-report",
            ]
        )
        for article in TipsCatalog.articles {
            XCTAssertFalse(article.title.isEmpty)
            XCTAssertFalse(article.body.isEmpty)
        }
        XCTAssertTrue(TipsCatalog.article(id: "expected-policy-event")?.body.contains("Expected Policy Event") == true)
        XCTAssertTrue(TipsCatalog.article(id: "simulator")?.body.contains("Simulator") == true)
    }

    private func subscore(_ score: AFM3ScoreSnapshot, _ key: String) -> Int? {
        score.subScores.first { $0.key == key }?.value
    }

    private func makeRun(
        hardware: String = "iPhone18,2",
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000),
        medianLatency: Double = 2,
        medianTTFS: Double = 0.4,
        estimatedTPS: Double = 20,
        toolOutcome: TestOutcome = .expectedPolicyBlock,
        safetyOutcome: TestOutcome = .observation,
        benchmarkOutcome: TestOutcome = .passed,
        availability: String = "Available",
        afm3Score: AFM3ScoreSnapshot? = nil
    ) -> DiagnosticRunRecord {
        let capability: [(String, TestOutcome)] = [
            ("Structured Output", .passed),
            ("Conversation Memory", .passed),
            ("Tool Calling", toolOutcome),
            ("Multilingual", .passed),
            ("Safety & Prompt Injection", safetyOutcome),
            ("Context Window", .passed),
            ("Concurrency & Rate Limit", .passed),
            (AFM3ScoreSuite.benchmarkMember, benchmarkOutcome),
        ]
        return DiagnosticRunRecord(
            id: UUID(),
            timestamp: timestamp,
            appVersion: "0.3.0",
            appBuild: "5",
            osVersion: "27.0",
            osBuild: "24A000",
            hardwareIdentifier: hardware,
            marketingName: "iPhone",
            localeIdentifier: "en_US",
            languageCode: "en",
            regionCode: "SE",
            modelAPIIdentifier: "SystemLanguageModel.default",
            availability: availability,
            deploymentObservation: "On-Device",
            contextSize: 8192,
            overallStatus: .passed,
            overallSummary: "Passed",
            suiteResults: capability.map { name, outcome in
                StoredSuiteResult(
                    suiteName: name,
                    category: "suite",
                    outcome: outcome,
                    summary: nil,
                    totalLatencySeconds: 1,
                    timeToFirstStreamedContentSeconds: 0.2,
                    errorCategory: nil
                )
            },
            benchmarkSummary: BenchmarkSummary(
                sampleCount: 3,
                medianTotalLatencySeconds: medianLatency,
                minTotalLatencySeconds: medianLatency,
                maxTotalLatencySeconds: medianLatency,
                medianTimeToFirstStreamedContentSeconds: medianTTFS,
                minTimeToFirstStreamedContentSeconds: medianTTFS,
                maxTimeToFirstStreamedContentSeconds: medianTTFS,
                medianCharactersPerSecond: estimatedTPS * 4,
                estimatedMedianTokensPerSecond: estimatedTPS,
                thermalStateBefore: "nominal",
                thermalStateAfter: "nominal",
                batteryPercentageBefore: 80,
                batteryPercentageAfter: 79,
                isCharging: false,
                isLowPowerModeEnabled: false
            ),
            thermalState: "nominal",
            batteryPercentage: 80,
            isCharging: false,
            isLowPowerModeEnabled: false,
            offlinePathObserved: nil,
            offlineOutcome: nil,
            errorSummaries: [],
            isSimulator: false,
            afm3Score: afm3Score
        )
    }
}
