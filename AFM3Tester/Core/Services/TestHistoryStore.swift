import Foundation

/// Local-only, non-prompt diagnostic run history.
/// No iCloud, no network, fail-soft on corruption or unsupported schema versions.
@MainActor
@Observable
final class TestHistoryStore {
    static let shared = TestHistoryStore()
    static let defaultRetentionLimit = 50
    static let fileName = "diagnostic-run-history.json"

    private(set) var runs: [DiagnosticRunRecord] = []
    private(set) var lastLoadError: String?
    var retentionLimit: Int

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileURL: URL? = nil,
        retentionLimit: Int = TestHistoryStore.defaultRetentionLimit
    ) {
        self.retentionLimit = max(1, retentionLimit)
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let dir = base.appendingPathComponent("AFM3Tester", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent(Self.fileName)
        }
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func load() {
        lastLoadError = nil
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            runs = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let envelope = try decodeEnvelope(from: data)
            runs = envelope.runs
                .filter { $0.schemaVersion <= HistorySchemaVersion.current }
                .sorted { $0.timestamp > $1.timestamp }
            applyRetention()
        } catch {
            lastLoadError = "History load recovered from corruption: \(error.localizedDescription)"
            runs = []
            // Fail-soft: quarantine unreadable file and start empty.
            let quarantine = fileURL.appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970))")
            try? FileManager.default.moveItem(at: fileURL, to: quarantine)
        }
    }

    func saveRun(_ record: DiagnosticRunRecord) {
        var next = record
        if next.schemaVersion != HistorySchemaVersion.current {
            // Reject unsupported future schema writes by normalizing to current.
            next = DiagnosticRunRecord(
                schemaVersion: HistorySchemaVersion.current,
                id: record.id,
                timestamp: record.timestamp,
                appVersion: record.appVersion,
                appBuild: record.appBuild,
                osVersion: record.osVersion,
                osBuild: record.osBuild,
                hardwareIdentifier: record.hardwareIdentifier,
                marketingName: record.marketingName,
                localeIdentifier: record.localeIdentifier,
                languageCode: record.languageCode,
                regionCode: record.regionCode,
                modelAPIIdentifier: record.modelAPIIdentifier,
                availability: record.availability,
                deploymentObservation: record.deploymentObservation,
                contextSize: record.contextSize,
                overallStatus: record.overallStatus,
                overallSummary: record.overallSummary,
                suiteResults: record.suiteResults,
                benchmarkSummary: record.benchmarkSummary,
                thermalState: record.thermalState,
                batteryPercentage: record.batteryPercentage,
                isCharging: record.isCharging,
                isLowPowerModeEnabled: record.isLowPowerModeEnabled,
                offlinePathObserved: record.offlinePathObserved,
                offlineOutcome: record.offlineOutcome,
                offlineChecksPassed: record.offlineChecksPassed,
                offlineChecksTotal: record.offlineChecksTotal,
                offlineCompletedAt: record.offlineCompletedAt,
                errorSummaries: record.errorSummaries,
                policyEventSummaries: record.policyEventSummaries,
                isSimulator: record.isSimulator
            )
        }
        runs.insert(next, at: 0)
        applyRetention()
        persist()
    }

    func deleteRun(id: UUID) {
        runs.removeAll { $0.id == id }
        persist()
    }

    func deleteAll() {
        runs = []
        persist()
    }

    func run(id: UUID) -> DiagnosticRunRecord? {
        runs.first { $0.id == id }
    }

    // MARK: - Persistence helpers (testable)

    static func decodeEnvelope(
        from data: Data,
        decoder: JSONDecoder = {
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            return d
        }()
    ) throws -> HistoryFileEnvelope {
        // Prefer envelope; fall back to bare array for older experiments.
        if let envelope = try? decoder.decode(HistoryFileEnvelope.self, from: data) {
            if envelope.schemaVersion > HistorySchemaVersion.current {
                throw HistoryStoreError.unsupportedSchema(envelope.schemaVersion)
            }
            let compatible = envelope.runs.filter { $0.schemaVersion <= HistorySchemaVersion.current }
            return HistoryFileEnvelope(schemaVersion: HistorySchemaVersion.current, runs: compatible)
        }
        if let bare = try? decoder.decode([DiagnosticRunRecord].self, from: data) {
            let compatible = bare.filter { $0.schemaVersion <= HistorySchemaVersion.current }
            return HistoryFileEnvelope(schemaVersion: HistorySchemaVersion.current, runs: compatible)
        }
        throw HistoryStoreError.corrupted
    }

    static func applyRetention(to runs: [DiagnosticRunRecord], limit: Int) -> [DiagnosticRunRecord] {
        let sorted = runs.sorted { $0.timestamp > $1.timestamp }
        guard sorted.count > limit else { return sorted }
        return Array(sorted.prefix(limit))
    }

    private func applyRetention() {
        runs = Self.applyRetention(to: runs, limit: retentionLimit)
    }

    private func persist() {
        let envelope = HistoryFileEnvelope(schemaVersion: HistorySchemaVersion.current, runs: runs)
        do {
            let data = try encoder.encode(envelope)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            lastLoadError = "Failed to persist history: \(error.localizedDescription)"
        }
    }

    private func decodeEnvelope(from data: Data) throws -> HistoryFileEnvelope {
        try Self.decodeEnvelope(from: data, decoder: decoder)
    }
}

enum HistoryStoreError: Error, LocalizedError {
    case unsupportedSchema(Int)
    case corrupted

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            "Unsupported history schema version \(version)"
        case .corrupted:
            "Corrupted history file"
        }
    }
}
