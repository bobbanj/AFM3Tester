import Foundation

/// Versioned local history schema. Bump when persisted fields change incompatibly.
enum HistorySchemaVersion: Sendable {
    /// v2 adds policyEventSummaries (decoded with default [] for older records).
    /// v3 adds offline check counts / completion timestamp for Device Report consistency.
    /// v4 adds an optional AFM3 Score snapshot. Older records decode with a nil score and can be derived.
    nonisolated static let current = 4
}

/// Concise per-suite summary stored in local history (no prompts or model bodies).
struct StoredSuiteResult: Codable, Sendable, Hashable, Identifiable {
    var id: String { suiteName }
    let suiteName: String
    let category: String
    let outcome: TestOutcome
    let summary: String?
    let totalLatencySeconds: Double?
    let timeToFirstStreamedContentSeconds: Double?
    let errorCategory: String?
}

struct StoredErrorSummary: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let testName: String
    let category: ErrorCategory
    let redactedDescription: String
}

struct StoredPolicyEventSummary: Codable, Sendable, Hashable, Identifiable {
    let id: UUID
    let testName: String
    let kind: PolicyEventKind
    let redactedSummary: String
}

/// Redacted, non-prompt diagnostic snapshot for one completed run.
struct DiagnosticRunRecord: Codable, Sendable, Identifiable, Hashable {
    let schemaVersion: Int
    let id: UUID
    let timestamp: Date
    let appVersion: String
    let appBuild: String
    let osVersion: String
    let osBuild: String
    let hardwareIdentifier: String
    let marketingName: String
    let localeIdentifier: String
    let languageCode: String
    let regionCode: String
    let modelAPIIdentifier: String
    let availability: String
    let deploymentObservation: String
    let contextSize: Int?
    let overallStatus: OverallRunStatus
    let overallSummary: String
    let suiteResults: [StoredSuiteResult]
    let benchmarkSummary: BenchmarkSummary?
    let thermalState: String?
    let batteryPercentage: Double?
    let isCharging: Bool?
    let isLowPowerModeEnabled: Bool?
    let offlinePathObserved: Bool?
    let offlineOutcome: TestOutcome?
    /// Passed validation checks from the latest Offline Verification run, when available.
    let offlineChecksPassed: Int?
    /// Total validation checks from the latest Offline Verification run, when available.
    let offlineChecksTotal: Int?
    /// Completion time of the latest Offline Verification evidence record, when available.
    let offlineCompletedAt: Date?
    let errorSummaries: [StoredErrorSummary]
    let policyEventSummaries: [StoredPolicyEventSummary]
    let isSimulator: Bool
    /// Present for runs saved by 0.3 and later. Older history derives a score at read time.
    let afm3Score: AFM3ScoreSnapshot?

    nonisolated init(
        schemaVersion: Int = HistorySchemaVersion.current,
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appVersion: String,
        appBuild: String,
        osVersion: String,
        osBuild: String,
        hardwareIdentifier: String,
        marketingName: String,
        localeIdentifier: String,
        languageCode: String,
        regionCode: String,
        modelAPIIdentifier: String,
        availability: String,
        deploymentObservation: String,
        contextSize: Int?,
        overallStatus: OverallRunStatus,
        overallSummary: String,
        suiteResults: [StoredSuiteResult],
        benchmarkSummary: BenchmarkSummary?,
        thermalState: String?,
        batteryPercentage: Double?,
        isCharging: Bool?,
        isLowPowerModeEnabled: Bool?,
        offlinePathObserved: Bool?,
        offlineOutcome: TestOutcome?,
        offlineChecksPassed: Int? = nil,
        offlineChecksTotal: Int? = nil,
        offlineCompletedAt: Date? = nil,
        errorSummaries: [StoredErrorSummary],
        policyEventSummaries: [StoredPolicyEventSummary] = [],
        isSimulator: Bool,
        afm3Score: AFM3ScoreSnapshot? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.timestamp = timestamp
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.osVersion = osVersion
        self.osBuild = osBuild
        self.hardwareIdentifier = hardwareIdentifier
        self.marketingName = marketingName
        self.localeIdentifier = localeIdentifier
        self.languageCode = languageCode
        self.regionCode = regionCode
        self.modelAPIIdentifier = modelAPIIdentifier
        self.availability = availability
        self.deploymentObservation = deploymentObservation
        self.contextSize = contextSize
        self.overallStatus = overallStatus
        self.overallSummary = overallSummary
        self.suiteResults = suiteResults
        self.benchmarkSummary = benchmarkSummary
        self.thermalState = thermalState
        self.batteryPercentage = batteryPercentage
        self.isCharging = isCharging
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.offlinePathObserved = offlinePathObserved
        self.offlineOutcome = offlineOutcome
        self.offlineChecksPassed = offlineChecksPassed
        self.offlineChecksTotal = offlineChecksTotal
        self.offlineCompletedAt = offlineCompletedAt
        self.errorSummaries = errorSummaries
        self.policyEventSummaries = policyEventSummaries
        self.isSimulator = isSimulator
        self.afm3Score = afm3Score
    }

    nonisolated init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try c.decode(UUID.self, forKey: .id)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        appVersion = try c.decode(String.self, forKey: .appVersion)
        appBuild = try c.decode(String.self, forKey: .appBuild)
        osVersion = try c.decode(String.self, forKey: .osVersion)
        osBuild = try c.decode(String.self, forKey: .osBuild)
        hardwareIdentifier = try c.decode(String.self, forKey: .hardwareIdentifier)
        marketingName = try c.decode(String.self, forKey: .marketingName)
        localeIdentifier = try c.decode(String.self, forKey: .localeIdentifier)
        languageCode = try c.decode(String.self, forKey: .languageCode)
        regionCode = try c.decode(String.self, forKey: .regionCode)
        modelAPIIdentifier = try c.decode(String.self, forKey: .modelAPIIdentifier)
        availability = try c.decode(String.self, forKey: .availability)
        deploymentObservation = try c.decode(String.self, forKey: .deploymentObservation)
        contextSize = try c.decodeIfPresent(Int.self, forKey: .contextSize)
        overallStatus = try c.decode(OverallRunStatus.self, forKey: .overallStatus)
        overallSummary = try c.decode(String.self, forKey: .overallSummary)
        suiteResults = try c.decode([StoredSuiteResult].self, forKey: .suiteResults)
        benchmarkSummary = try c.decodeIfPresent(BenchmarkSummary.self, forKey: .benchmarkSummary)
        thermalState = try c.decodeIfPresent(String.self, forKey: .thermalState)
        batteryPercentage = try c.decodeIfPresent(Double.self, forKey: .batteryPercentage)
        isCharging = try c.decodeIfPresent(Bool.self, forKey: .isCharging)
        isLowPowerModeEnabled = try c.decodeIfPresent(Bool.self, forKey: .isLowPowerModeEnabled)
        offlinePathObserved = try c.decodeIfPresent(Bool.self, forKey: .offlinePathObserved)
        offlineOutcome = try c.decodeIfPresent(TestOutcome.self, forKey: .offlineOutcome)
        offlineChecksPassed = try c.decodeIfPresent(Int.self, forKey: .offlineChecksPassed)
        offlineChecksTotal = try c.decodeIfPresent(Int.self, forKey: .offlineChecksTotal)
        offlineCompletedAt = try c.decodeIfPresent(Date.self, forKey: .offlineCompletedAt)
        errorSummaries = try c.decodeIfPresent([StoredErrorSummary].self, forKey: .errorSummaries) ?? []
        policyEventSummaries = try c.decodeIfPresent([StoredPolicyEventSummary].self, forKey: .policyEventSummaries) ?? []
        isSimulator = try c.decode(Bool.self, forKey: .isSimulator)
        afm3Score = try c.decodeIfPresent(AFM3ScoreSnapshot.self, forKey: .afm3Score)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(id, forKey: .id)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(appVersion, forKey: .appVersion)
        try c.encode(appBuild, forKey: .appBuild)
        try c.encode(osVersion, forKey: .osVersion)
        try c.encode(osBuild, forKey: .osBuild)
        try c.encode(hardwareIdentifier, forKey: .hardwareIdentifier)
        try c.encode(marketingName, forKey: .marketingName)
        try c.encode(localeIdentifier, forKey: .localeIdentifier)
        try c.encode(languageCode, forKey: .languageCode)
        try c.encode(regionCode, forKey: .regionCode)
        try c.encode(modelAPIIdentifier, forKey: .modelAPIIdentifier)
        try c.encode(availability, forKey: .availability)
        try c.encode(deploymentObservation, forKey: .deploymentObservation)
        try c.encodeIfPresent(contextSize, forKey: .contextSize)
        try c.encode(overallStatus, forKey: .overallStatus)
        try c.encode(overallSummary, forKey: .overallSummary)
        try c.encode(suiteResults, forKey: .suiteResults)
        try c.encodeIfPresent(benchmarkSummary, forKey: .benchmarkSummary)
        try c.encodeIfPresent(thermalState, forKey: .thermalState)
        try c.encodeIfPresent(batteryPercentage, forKey: .batteryPercentage)
        try c.encodeIfPresent(isCharging, forKey: .isCharging)
        try c.encodeIfPresent(isLowPowerModeEnabled, forKey: .isLowPowerModeEnabled)
        try c.encodeIfPresent(offlinePathObserved, forKey: .offlinePathObserved)
        try c.encodeIfPresent(offlineOutcome, forKey: .offlineOutcome)
        try c.encodeIfPresent(offlineChecksPassed, forKey: .offlineChecksPassed)
        try c.encodeIfPresent(offlineChecksTotal, forKey: .offlineChecksTotal)
        try c.encodeIfPresent(offlineCompletedAt, forKey: .offlineCompletedAt)
        try c.encode(errorSummaries, forKey: .errorSummaries)
        try c.encode(policyEventSummaries, forKey: .policyEventSummaries)
        try c.encode(isSimulator, forKey: .isSimulator)
        try c.encodeIfPresent(afm3Score, forKey: .afm3Score)
    }
}

struct HistoryFileEnvelope: Codable, Sendable {
    let schemaVersion: Int
    var runs: [DiagnosticRunRecord]
}
