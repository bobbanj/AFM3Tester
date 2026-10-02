import Foundation

enum DiagnosticRunFactory: Sendable {

    @MainActor
    static func makeRun(
        from store: DiagnosticStore,
        availability: String,
        contextSize: Int?,
        appVersion: String? = nil,
        appBuild: String? = nil
    ) -> DiagnosticRunRecord {
        let device = DeviceInfoProvider.captureSnapshot()
        let marketing = DeviceMarketingNameResolver.marketingName(forHardwareIdentifier: device.deviceModel)
        let version = appVersion
            ?? AppRelease.marketingVersion
        let build = appBuild
            ?? AppRelease.buildNumber

        let suiteResults: [StoredSuiteResult] = store.testResults.values.map { result in
            StoredSuiteResult(
                suiteName: result.testName,
                category: result.category,
                outcome: result.outcome,
                summary: result.message.map { ReportRedactor.redactFreeTextPreservingMetrics($0) },
                totalLatencySeconds: result.latency?.totalGenerationSeconds,
                timeToFirstStreamedContentSeconds: result.latency?.timeToFirstTokenSeconds,
                errorCategory: result.rawError == nil ? nil : result.outcome.rawValue
            )
        }
        .sorted { $0.suiteName < $1.suiteName }

        let outcomes = suiteResults.map(\.outcome)
        let overall = OverallStatusAggregator.aggregate(outcomes)
        let summary = OverallStatusAggregator.conciseSummary(from: outcomes)

        let offlineSnapshot = resolveOfflineSnapshot(from: store, suiteResults: suiteResults)

        let errorSummaries = store.errorLog.suffix(20).map { entry in
            StoredErrorSummary(
                id: entry.id,
                testName: entry.testName,
                category: entry.category,
                redactedDescription: ReportRedactor.redact(entry.localizedDescription)
            )
        }

        let policySummaries = store.policyEvents.suffix(20).map { entry in
            StoredPolicyEventSummary(
                id: entry.id,
                testName: entry.testName,
                kind: entry.kind,
                redactedSummary: ReportRedactor.redact(entry.summary)
            )
        }

        let benchmarkSamples = store.currentBenchmarkSamples.isEmpty
            ? store.benchmarks
            : store.currentBenchmarkSamples
        let benchmarkSummary: BenchmarkSummary? = {
            guard !benchmarkSamples.isEmpty else { return nil }
            return BenchmarkStatistics.summarize(samples: benchmarkSamples)
        }()

        let score = AFM3ScoreCalculator.makeSnapshot(
            suiteResults: suiteResults,
            benchmarkSummary: benchmarkSummary,
            provenance: .stored
        )

        return DiagnosticRunRecord(
            appVersion: version,
            appBuild: build,
            osVersion: device.osVersion,
            osBuild: device.osBuild,
            hardwareIdentifier: device.deviceModel,
            marketingName: marketing,
            localeIdentifier: device.localeIdentifier,
            languageCode: device.languageCode,
            regionCode: device.regionCode,
            modelAPIIdentifier: ModelMetadataFormatter.apiModelIdentifier,
            availability: availability,
            deploymentObservation: FoundationModelService.deployment,
            contextSize: contextSize,
            overallStatus: overall,
            overallSummary: summary,
            suiteResults: suiteResults,
            benchmarkSummary: benchmarkSummary,
            thermalState: device.thermalState,
            batteryPercentage: device.batteryLevel.map { $0 * 100 },
            isCharging: device.isCharging,
            isLowPowerModeEnabled: device.isLowPowerModeEnabled,
            offlinePathObserved: offlineSnapshot.pathObservedUnsatisfied,
            offlineOutcome: offlineSnapshot.outcome,
            offlineChecksPassed: offlineSnapshot.checksPassed,
            offlineChecksTotal: offlineSnapshot.checksTotal,
            offlineCompletedAt: offlineSnapshot.completedAt,
            errorSummaries: Array(errorSummaries),
            policyEventSummaries: Array(policySummaries),
            isSimulator: device.isSimulator,
            afm3Score: score
        )
    }

    /// Resolves Offline Verification from live test results, suite list, or evidence records.
    /// Prefer evidence when present so Device Report matches a completed Offline Verification UI run.
    @MainActor
    private static func resolveOfflineSnapshot(
        from store: DiagnosticStore,
        suiteResults: [StoredSuiteResult]
    ) -> OfflineSnapshot {
        let suiteName = OfflineObservationFormatter.suiteName
        let liveResult = store.testResults[suiteName]
        let evidence = store.offlineEvidenceRecords.last
        let suiteOutcome = suiteResults.first(where: { $0.suiteName == suiteName })?.outcome

        let outcome = liveResult?.outcome ?? evidence?.testOutcome ?? suiteOutcome
        let checks = liveResult?.validationChecks ?? evidence?.checks ?? []
        let counts = OfflineObservationFormatter.checkCounts(from: checks)

        let pathUnsatisfied: Bool? = {
            if let evidence {
                return !evidence.pathSatisfied
            }
            if liveResult != nil || suiteOutcome != nil {
                // Completed offline suite without evidence: path state unknown.
                return nil
            }
            return nil
        }()

        guard outcome != nil || evidence != nil else {
            return OfflineSnapshot(
                outcome: nil,
                pathObservedUnsatisfied: nil,
                checksPassed: nil,
                checksTotal: nil,
                completedAt: nil
            )
        }

        return OfflineSnapshot(
            outcome: outcome,
            pathObservedUnsatisfied: pathUnsatisfied,
            checksPassed: checks.isEmpty ? nil : counts.passed,
            checksTotal: checks.isEmpty ? nil : counts.total,
            completedAt: evidence?.completedAt ?? liveResult?.recordedAt
        )
    }

    private struct OfflineSnapshot {
        let outcome: TestOutcome?
        let pathObservedUnsatisfied: Bool?
        let checksPassed: Int?
        let checksTotal: Int?
        let completedAt: Date?
    }
}
