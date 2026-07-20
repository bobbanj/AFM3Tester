import XCTest
@testable import AFM3Tester

@MainActor
final class TestHistoryStoreTests: XCTestCase {
    private var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AFM3History-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        super.tearDown()
    }

    func testEncodeDecodeRoundTrip() throws {
        let store = TestHistoryStore(fileURL: tempURL, retentionLimit: 50)
        let run = sampleRun()
        store.saveRun(run)
        let reloaded = TestHistoryStore(fileURL: tempURL, retentionLimit: 50)
        XCTAssertEqual(reloaded.runs.count, 1)
        XCTAssertEqual(reloaded.runs.first?.id, run.id)
        XCTAssertEqual(reloaded.runs.first?.schemaVersion, HistorySchemaVersion.current)
    }

    func testRetentionLimit() {
        let store = TestHistoryStore(fileURL: tempURL, retentionLimit: 2)
        store.saveRun(sampleRun(offset: 0))
        store.saveRun(sampleRun(offset: 1))
        store.saveRun(sampleRun(offset: 2))
        XCTAssertEqual(store.runs.count, 2)
    }

    func testDeleteOneAndDeleteAll() {
        let store = TestHistoryStore(fileURL: tempURL, retentionLimit: 50)
        let a = sampleRun(offset: 0)
        let b = sampleRun(offset: 1)
        store.saveRun(a)
        store.saveRun(b)
        store.deleteRun(id: a.id)
        XCTAssertEqual(store.runs.count, 1)
        XCTAssertEqual(store.runs.first?.id, b.id)
        store.deleteAll()
        XCTAssertTrue(store.runs.isEmpty)
    }

    func testCorruptedHistoryRecovery() throws {
        try Data("not-json".utf8).write(to: tempURL)
        let store = TestHistoryStore(fileURL: tempURL, retentionLimit: 50)
        XCTAssertTrue(store.runs.isEmpty)
        XCTAssertNotNil(store.lastLoadError)
    }

    func testUnsupportedSchemaRejectedFromEnvelope() throws {
        let future = """
        {"schemaVersion":99,"runs":[]}
        """
        let data = Data(future.utf8)
        XCTAssertThrowsError(try TestHistoryStore.decodeEnvelope(from: data)) { error in
            guard case HistoryStoreError.unsupportedSchema(99) = error else {
                return XCTFail("Unexpected \(error)")
            }
        }
    }

    func testSchemaV1MissingPolicyEventsDecodesAsEmpty() throws {
        let run = sampleRun()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var object = try JSONSerialization.jsonObject(with: encoder.encode(run)) as! [String: Any]
        object["schemaVersion"] = 1
        object.removeValue(forKey: "policyEventSummaries")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DiagnosticRunRecord.self, from: data)
        XCTAssertTrue(decoded.policyEventSummaries.isEmpty)
    }

    private func sampleRun(offset: TimeInterval = 0) -> DiagnosticRunRecord {
        DiagnosticRunRecord(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000 + offset),
            appVersion: "0.2.0",
            appBuild: "2",
            osVersion: "27.0",
            osBuild: "24A000",
            hardwareIdentifier: "iPhone18,2",
            marketingName: "iPhone 17 Pro Max",
            localeIdentifier: "en_US",
            languageCode: "en",
            regionCode: "SE",
            modelAPIIdentifier: "SystemLanguageModel.default",
            availability: "Available",
            deploymentObservation: "On-Device",
            contextSize: 8192,
            overallStatus: .passed,
            overallSummary: "Passed",
            suiteResults: [],
            benchmarkSummary: nil,
            thermalState: "nominal",
            batteryPercentage: 50,
            isCharging: false,
            isLowPowerModeEnabled: false,
            offlinePathObserved: nil,
            offlineOutcome: nil,
            errorSummaries: [],
            policyEventSummaries: [],
            isSimulator: false
        )
    }
}
