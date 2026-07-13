import Foundation
import FoundationModels

// MARK: - Service Types

struct SessionCreationResult: Sendable {
    let session: LanguageModelSession
    let creationTimeSeconds: Double
}

struct InferenceResponseResult: Sendable {
    let content: String
    let metrics: LatencyMetrics
}

struct StreamingInferenceResult: Sendable {
    let content: String
    let metrics: LatencyMetrics
}

struct GeneratingInferenceResult<Content: Generable & Sendable>: Sendable {
    let content: Content
    let metrics: LatencyMetrics
}

// MARK: - Diagnostic Recording

/// Allows the inference actor to log errors without MainActor coupling.
protocol DiagnosticRecording: Sendable {
    func recordError(_ entry: ErrorLogEntry) async
}

// MARK: - Foundation Model Service

actor FoundationModelService {
    static let modelName = "SystemLanguageModel.default"
    static let deployment = "On-Device (SystemLanguageModel)"

    private let model: SystemLanguageModel
    private let recordError: @Sendable (ErrorLogEntry) async -> Void
    private let recordSuccessfulInference: @Sendable () async -> Void

    init(
        model: SystemLanguageModel = .default,
        diagnosticRecorder: (any DiagnosticRecording)? = nil,
        recordError: @escaping @Sendable (ErrorLogEntry) async -> Void = { _ in },
        recordSuccessfulInference: @escaping @Sendable () async -> Void = {}
    ) {
        self.model = model
        if let diagnosticRecorder {
            self.recordError = { entry in
                await diagnosticRecorder.recordError(entry)
            }
        } else {
            self.recordError = recordError
        }
        self.recordSuccessfulInference = recordSuccessfulInference
    }

    var modelAvailability: SystemLanguageModel.Availability {
        model.availability
    }

    var isModelAvailable: Bool {
        model.isAvailable
    }

    var contextSize: Int {
        model.contextSize
    }

    var availabilityDescription: String {
        Self.availabilityText(for: model.availability)
    }

    func supportsLocale(_ locale: Locale = .current) -> Bool {
        model.supportsLocale(locale)
    }

    // MARK: - Sessions

    func makeSession(
        instructions: String? = nil,
        tools: [any Tool] = []
    ) -> SessionCreationResult {
        let start = ContinuousClock.now
        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: instructions
        )
        let elapsed = start.duration(to: ContinuousClock.now)
        return SessionCreationResult(
            session: session,
            creationTimeSeconds: Self.seconds(from: elapsed)
        )
    }

    func rehydrateSession(
        from transcript: Transcript,
        tools: [any Tool] = [],
        instructions: String? = nil
    ) -> SessionCreationResult {
        let start = ContinuousClock.now
        let session: LanguageModelSession
        if transcript.isEmpty, let instructions {
            session = LanguageModelSession(
                model: model,
                tools: tools,
                instructions: instructions
            )
        } else {
            session = LanguageModelSession(
                model: model,
                tools: tools,
                transcript: transcript
            )
        }
        let elapsed = start.duration(to: ContinuousClock.now)
        return SessionCreationResult(
            session: session,
            creationTimeSeconds: Self.seconds(from: elapsed)
        )
    }

    func exportTranscript(from session: LanguageModelSession) -> Transcript {
        session.transcript
    }

    // MARK: - Inference

    func respond(
        session: LanguageModelSession,
        prompt: String,
        options: GenerationOptions = GenerationOptions(),
        testName: String = "Inference"
    ) async throws -> InferenceResponseResult {
        let start = ContinuousClock.now
        do {
            let response = try await session.respond(to: prompt, options: options)
            let elapsed = start.duration(to: ContinuousClock.now)
            let content = response.content
            let metrics = await Self.makeMetrics(
                totalGeneration: Self.seconds(from: elapsed),
                inputCharacters: prompt.count,
                outputCharacters: content.count
            )
            await recordSuccessfulInference()
            return InferenceResponseResult(content: content, metrics: metrics)
        } catch {
            await logError(error, testName: testName)
            throw error
        }
    }

    func streamRespond(
        session: LanguageModelSession,
        prompt: String,
        options: GenerationOptions = GenerationOptions(),
        onPartial: @Sendable @escaping (String) -> Void,
        testName: String = "Streaming Inference"
    ) async throws -> StreamingInferenceResult {
        let start = ContinuousClock.now
        var firstTokenTime: Duration?
        var latestContent = ""

        do {
            let stream = session.streamResponse(to: prompt, options: options)
            for try await snapshot in stream {
                try Task.checkCancellation()

                if firstTokenTime == nil {
                    firstTokenTime = start.duration(to: ContinuousClock.now)
                }

                latestContent = snapshot.content
                onPartial(latestContent)
            }

            let totalElapsed = start.duration(to: ContinuousClock.now)
            let metrics = await Self.makeMetrics(
                timeToFirstToken: firstTokenTime.map { Self.seconds(from: $0) },
                totalGeneration: Self.seconds(from: totalElapsed),
                inputCharacters: prompt.count,
                outputCharacters: latestContent.count
            )
            await recordSuccessfulInference()
            return StreamingInferenceResult(content: latestContent, metrics: metrics)
        } catch is CancellationError {
            await logError(CancellationError(), testName: testName)
            throw CancellationError()
        } catch {
            await logError(error, testName: testName)
            throw error
        }
    }

    func respondGenerating<Content: Generable & Sendable>(
        session: LanguageModelSession,
        prompt: String,
        type: Content.Type = Content.self,
        options: GenerationOptions = GenerationOptions(),
        testName: String = "Guided Generation"
    ) async throws -> GeneratingInferenceResult<Content> {
        let start = ContinuousClock.now
        do {
            let response = try await session.respond(
                to: prompt,
                generating: type,
                options: options
            )
            let elapsed = start.duration(to: ContinuousClock.now)
            let metrics = await Self.makeMetrics(
                totalGeneration: Self.seconds(from: elapsed),
                inputCharacters: prompt.count,
                outputCharacters: String(describing: response.content).count
            )
            await recordSuccessfulInference()
            return GeneratingInferenceResult(content: response.content, metrics: metrics)
        } catch {
            await logError(error, testName: testName)
            throw error
        }
    }

    func tokenCount(for prompt: String) async throws -> Int {
        if #available(iOS 26.4, *) {
            return try await model.tokenCount(for: prompt)
        }
        return max(1, prompt.count / 4)
    }

    // MARK: - Error Logging

    private func logError(_ error: Error, testName: String) async {
        let availability = availabilityDescription
        let entry = await MainActor.run {
            ErrorLogEntry(
                testName: testName,
                availabilityState: availability,
                localizedDescription: error.localizedDescription,
                debugDescription: String(reflecting: error),
                category: ErrorClassifier.classify(error: error)
            )
        }
        await recordError(entry)
    }

    private static func makeMetrics(
        sessionCreation: TimeInterval? = nil,
        timeToFirstToken: TimeInterval? = nil,
        totalGeneration: TimeInterval,
        inputCharacters: Int,
        outputCharacters: Int
    ) async -> LatencyMetrics {
        await MainActor.run {
            LatencyMetrics.compute(
                sessionCreation: sessionCreation,
                timeToFirstToken: timeToFirstToken,
                totalGeneration: totalGeneration,
                inputCharacters: inputCharacters,
                outputCharacters: outputCharacters
            )
        }
    }

    nonisolated private static func seconds(from duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    nonisolated private static func availabilityText(
        for availability: SystemLanguageModel.Availability
    ) -> String {
        switch availability {
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
