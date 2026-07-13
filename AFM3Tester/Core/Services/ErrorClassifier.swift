import Foundation
import FoundationModels

enum ErrorClassifier: Sendable {

    nonisolated static func classify(error: Error) -> ErrorCategory {
        if error is CancellationError {
            return .cancellation
        }

        if let generationError = error as? LanguageModelSession.GenerationError {
            return classifyGenerationError(generationError)
        }

        if let toolCallError = error as? LanguageModelSession.ToolCallError {
            if let nested = classifyKnownError(toolCallError.underlyingError) {
                return nested
            }
            return .toolCallFailure
        }

        if let nsError = error as NSError? {
            if let known = classifyNSError(nsError) {
                return known
            }
        }

        if let known = classifyKnownError(error) {
            return known
        }

        return .unknown
    }

    @available(iOS 26.0, *)
    nonisolated private static func classifyGenerationError(
        _ error: LanguageModelSession.GenerationError
    ) -> ErrorCategory {
        switch error {
        case .exceededContextWindowSize:
            .contextLimit
        case .assetsUnavailable:
            .assetsUnavailable
        case .guardrailViolation:
            .guardrailResponse
        case .unsupportedGuide:
            .unsupportedGuide
        case .unsupportedLanguageOrLocale:
            .unsupportedLocale
        case .decodingFailure:
            .decodingFailure
        case .rateLimited:
            .rateLimit
        case .concurrentRequests:
            .concurrentRequest
        case .refusal:
            .refusal
        @unknown default:
            .unknown
        }
    }

    nonisolated private static func classifyNSError(_ error: NSError) -> ErrorCategory? {
        if error.domain == "FoundationModels" {
            return classifyFoundationModelsDomain(code: error.code, description: error.localizedDescription)
        }

        if error.domain == NSCocoaErrorDomain, error.code == NSUserCancelledError {
            return .cancellation
        }

        let combined = "\(error.domain) \(error.localizedDescription) \(error.userInfo)".lowercased()

        if combined.contains("simulator") || combined.contains("operationnotallowed") {
            return .simulatorUnsupported
        }
        if combined.contains("not eligible") || combined.contains("device") {
            return .unsupportedDevice
        }
        if combined.contains("not ready") || combined.contains("modelnotready") {
            return .modelNotReady
        }

        return nil
    }

    nonisolated private static func classifyFoundationModelsDomain(
        code: Int,
        description: String
    ) -> ErrorCategory {
        let lower = description.lowercased()
        if lower.contains("context") || lower.contains("window") {
            return .contextLimit
        }
        if lower.contains("rate") {
            return .rateLimit
        }
        if lower.contains("concurrent") {
            return .concurrentRequest
        }
        if lower.contains("guardrail") {
            return .guardrailResponse
        }
        if lower.contains("locale") || lower.contains("language") {
            return .unsupportedLocale
        }
        if lower.contains("simulator") {
            return .simulatorUnsupported
        }
        if lower.contains("asset") {
            return .assetsUnavailable
        }
        _ = code
        return .unknown
    }

    nonisolated private static func classifyKnownError(_ error: Error) -> ErrorCategory? {
        let reflected = String(reflecting: error).lowercased()
        let localized = error.localizedDescription.lowercased()
        let combined = "\(reflected) \(localized)"

        if combined.contains("cancellation") || combined.contains("cancelled") {
            return .cancellation
        }
        if combined.contains("simulator") || combined.contains("operationnotallowed") {
            return .simulatorUnsupported
        }
        if combined.contains("devicenoteligible") || combined.contains("not eligible") {
            return .unsupportedDevice
        }
        if combined.contains("modelnotready") || combined.contains("not ready") {
            return .modelNotReady
        }
        if combined.contains("appleintelligencenotenabled") {
            return .unsupportedDevice
        }
        if combined.contains("exceededcontext") || combined.contains("context window") {
            return .contextLimit
        }
        if combined.contains("ratelimit") || combined.contains("rate limit") {
            return .rateLimit
        }
        if combined.contains("concurrent") {
            return .concurrentRequest
        }
        if combined.contains("guardrail") {
            return .guardrailResponse
        }
        if combined.contains("unsupportedlanguage") || combined.contains("locale") {
            return .unsupportedLocale
        }
        if combined.contains("decoding") {
            return .decodingFailure
        }

        return nil
    }
}
