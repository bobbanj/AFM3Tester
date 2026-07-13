import Foundation

enum OfflineEvidenceRecorder: Sendable {
    nonisolated static func makeRecord(
        startedAt: Date,
        completedAt: Date,
        pathSnapshot: NetworkPathSnapshot,
        testResult: TestResult
    ) -> OfflineEvidenceRecord {
        OfflineEvidenceRecord(
            startedAt: startedAt,
            completedAt: completedAt,
            networkPathStatus: pathSnapshot.statusDescription,
            pathSatisfied: pathSnapshot.isSatisfied,
            availableInterfaces: pathSnapshot.availableInterfaces,
            monitorDisclaimer: SideEffectPolicy.monitorDisclaimer,
            testOutcome: testResult.outcome,
            checks: testResult.validationChecks,
            message: testResult.message
        )
    }
}
