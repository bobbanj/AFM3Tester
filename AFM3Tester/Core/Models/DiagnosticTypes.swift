import Foundation
import FoundationModels

// MARK: - Test Outcomes

enum TestOutcome: String, Codable, Sendable, CaseIterable {
    case passed
    case failed
    case unavailable
    case skipped
    case observation
}

// MARK: - Latency

struct LatencyMetrics: Codable, Sendable, Hashable {
    var sessionCreationSeconds: Double?
    var timeToFirstTokenSeconds: Double?
    var totalGenerationSeconds: Double?
    var charactersPerSecond: Double?
    var inputCharacterCount: Int?
    var outputCharacterCount: Int?

    static func compute(
        sessionCreation: TimeInterval? = nil,
        timeToFirstToken: TimeInterval? = nil,
        totalGeneration: TimeInterval,
        inputCharacters: Int,
        outputCharacters: Int
    ) -> LatencyMetrics {
        let cps: Double?
        if totalGeneration > 0, outputCharacters > 0 {
            cps = Double(outputCharacters) / totalGeneration
        } else {
            cps = nil
        }
        return LatencyMetrics(
            sessionCreationSeconds: sessionCreation,
            timeToFirstTokenSeconds: timeToFirstToken,
            totalGenerationSeconds: totalGeneration,
            charactersPerSecond: cps,
            inputCharacterCount: inputCharacters,
            outputCharacterCount: outputCharacters
        )
    }
}

// MARK: - Test Results

struct TestResult: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let testName: String
    let category: String
    let outcome: TestOutcome
    let message: String?
    let latency: LatencyMetrics?
    let validationChecks: [ValidationCheck]
    let manualRating: ManualQualityRating?
    let rawError: String?
    let recordedAt: Date

    nonisolated init(
        id: UUID = UUID(),
        testName: String,
        category: String = "general",
        outcome: TestOutcome,
        message: String? = nil,
        latency: LatencyMetrics? = nil,
        validationChecks: [ValidationCheck] = [],
        manualRating: ManualQualityRating? = nil,
        rawError: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.testName = testName
        self.category = category
        self.outcome = outcome
        self.message = message
        self.latency = latency
        self.validationChecks = validationChecks
        self.manualRating = manualRating
        self.rawError = rawError
        self.recordedAt = recordedAt
    }
}

// MARK: - Benchmark

struct BenchmarkSample: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let testName: String
    let repetition: Int
    let startedAt: Date
    let latency: LatencyMetrics
    let thermalState: String
    let batteryLevel: Double?
    let isLowPowerModeEnabled: Bool
    let isCharging: Bool

    nonisolated init(
        id: UUID = UUID(),
        testName: String,
        repetition: Int,
        startedAt: Date = Date(),
        latency: LatencyMetrics,
        thermalState: String,
        batteryLevel: Double?,
        isLowPowerModeEnabled: Bool,
        isCharging: Bool
    ) {
        self.id = id
        self.testName = testName
        self.repetition = repetition
        self.startedAt = startedAt
        self.latency = latency
        self.thermalState = thermalState
        self.batteryLevel = batteryLevel
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.isCharging = isCharging
    }
}

// MARK: - Error Classification

enum ErrorCategory: String, Codable, Sendable, CaseIterable {
    case modelNotReady
    case unsupportedDevice
    case unsupportedLocale
    case guardrailResponse
    case contextLimit
    case rateLimit
    case concurrentRequest
    case cancellation
    case simulatorUnsupported
    case decodingFailure
    case assetsUnavailable
    case refusal
    case unsupportedGuide
    case toolCallFailure
    case unknown
}

struct ErrorLogEntry: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let testName: String
    let availabilityState: String
    let localizedDescription: String
    let debugDescription: String
    let category: ErrorCategory
    let nestedDetails: String?

    nonisolated init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        testName: String,
        availabilityState: String,
        localizedDescription: String,
        debugDescription: String,
        category: ErrorCategory,
        nestedDetails: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.testName = testName
        self.availabilityState = availabilityState
        self.localizedDescription = localizedDescription
        self.debugDescription = debugDescription
        self.category = category
        self.nestedDetails = nestedDetails
    }
}

// MARK: - Quality & Validation

enum ManualQualityRating: String, Codable, Sendable, CaseIterable {
    case good
    case acceptable
    case poor
    case unrated
}

struct ValidationCheck: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let passed: Bool
    let detail: String?

    nonisolated init(id: UUID = UUID(), name: String, passed: Bool, detail: String? = nil) {
        self.id = id
        self.name = name
        self.passed = passed
        self.detail = detail
    }
}

struct NetworkPathSnapshot: Codable, Sendable, Hashable {
    let statusDescription: String
    let isSatisfied: Bool
    let availableInterfaces: [String]
    let capturedAt: Date

    nonisolated init(
        statusDescription: String,
        isSatisfied: Bool,
        availableInterfaces: [String],
        capturedAt: Date = Date()
    ) {
        self.statusDescription = statusDescription
        self.isSatisfied = isSatisfied
        self.availableInterfaces = availableInterfaces
        self.capturedAt = capturedAt
    }
}

struct OfflineEvidenceRecord: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let startedAt: Date
    let completedAt: Date
    let networkPathStatus: String
    let pathSatisfied: Bool
    let availableInterfaces: [String]
    let monitorDisclaimer: String
    let testOutcome: TestOutcome
    let checks: [ValidationCheck]
    let message: String?

    nonisolated init(
        id: UUID = UUID(),
        startedAt: Date,
        completedAt: Date,
        networkPathStatus: String,
        pathSatisfied: Bool,
        availableInterfaces: [String],
        monitorDisclaimer: String,
        testOutcome: TestOutcome,
        checks: [ValidationCheck],
        message: String?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.networkPathStatus = networkPathStatus
        self.pathSatisfied = pathSatisfied
        self.availableInterfaces = availableInterfaces
        self.monitorDisclaimer = monitorDisclaimer
        self.testOutcome = testOutcome
        self.checks = checks
        self.message = message
    }
}

// MARK: - Device Snapshot

struct DeviceSnapshot: Codable, Sendable, Hashable {
    let osVersion: String
    let osBuild: String
    let deviceModel: String
    let localeIdentifier: String
    let languageCode: String
    let regionCode: String
    let thermalState: String
    let batteryLevel: Double?
    let isLowPowerModeEnabled: Bool
    let isCharging: Bool
    let isSimulator: Bool

    nonisolated init(
        osVersion: String,
        osBuild: String,
        deviceModel: String,
        localeIdentifier: String,
        languageCode: String,
        regionCode: String,
        thermalState: String,
        batteryLevel: Double?,
        isLowPowerModeEnabled: Bool,
        isCharging: Bool,
        isSimulator: Bool
    ) {
        self.osVersion = osVersion
        self.osBuild = osBuild
        self.deviceModel = deviceModel
        self.localeIdentifier = localeIdentifier
        self.languageCode = languageCode
        self.regionCode = regionCode
        self.thermalState = thermalState
        self.batteryLevel = batteryLevel
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.isCharging = isCharging
        self.isSimulator = isSimulator
    }
}

// MARK: - Diagnostic Report

extension SystemLanguageModel.Availability {
    var displayDescription: String {
        switch self {
        case .available:
            "Available"
        case .unavailable(.deviceNotEligible):
            "Unavailable — device not eligible"
        case .unavailable(.appleIntelligenceNotEnabled):
            "Unavailable — Apple Intelligence not enabled"
        case .unavailable(.modelNotReady):
            "Unavailable — model not ready"
        case .unavailable(let reason):
            "Unavailable — \(String(describing: reason))"
        }
    }
}

struct DiagnosticReport: Codable, Sendable {
    let generatedAt: Date
    let appVersion: String
    let device: DeviceSnapshot
    let modelAvailability: String
    let modelDescription: String
    let deploymentType: String?
    let contextWindowSize: Int?
    let contextWindowExposed: Bool
    let lastSuccessfulInference: Date?
    let testResults: [TestResult]
    let benchmarkSamples: [BenchmarkSample]
    let errors: [ErrorLogEntry]
    let offlineTestSucceeded: Bool?
    let offlineEvidenceRecords: [OfflineEvidenceRecord]
    let includePromptText: Bool
    let promptContents: [String]?

    nonisolated init(
        generatedAt: Date = Date(),
        appVersion: String,
        device: DeviceSnapshot,
        modelAvailability: String,
        modelDescription: String,
        deploymentType: String? = nil,
        contextWindowSize: Int? = nil,
        contextWindowExposed: Bool = false,
        lastSuccessfulInference: Date? = nil,
        testResults: [TestResult] = [],
        benchmarkSamples: [BenchmarkSample] = [],
        errors: [ErrorLogEntry] = [],
        offlineTestSucceeded: Bool? = nil,
        offlineEvidenceRecords: [OfflineEvidenceRecord] = [],
        includePromptText: Bool = false,
        promptContents: [String]? = nil
    ) {
        self.generatedAt = generatedAt
        self.appVersion = appVersion
        self.device = device
        self.modelAvailability = modelAvailability
        self.modelDescription = modelDescription
        self.deploymentType = deploymentType
        self.contextWindowSize = contextWindowSize
        self.contextWindowExposed = contextWindowExposed
        self.lastSuccessfulInference = lastSuccessfulInference
        self.testResults = testResults
        self.benchmarkSamples = benchmarkSamples
        self.errors = errors
        self.offlineTestSucceeded = offlineTestSucceeded
        self.offlineEvidenceRecords = offlineEvidenceRecords
        self.includePromptText = includePromptText
        self.promptContents = promptContents
    }
}
