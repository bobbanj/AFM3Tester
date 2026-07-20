import Foundation
import FoundationModels

/// Classifies tool-related errors without weakening side-effect policy.
enum ToolPolicyClassifier: Sendable {

    enum Classification: String, Codable, Sendable, Equatable {
        case expectedPolicyBlock
        case invalidArguments
        case unexpectedFailure
    }

    nonisolated static func classify(_ error: Error) -> Classification {
        if let themeError = error as? DemoThemeError {
            switch themeError {
            case .sideEffectsNotAllowed:
                return .expectedPolicyBlock
            case .invalidTheme:
                return .invalidArguments
            }
        }

        if let toolCallError = error as? LanguageModelSession.ToolCallError {
            return classify(toolCallError.underlyingError)
        }

        let reflected = String(reflecting: error).lowercased()
        let localized = error.localizedDescription.lowercased()
        let combined = "\(reflected) \(localized)"

        if combined.contains("sideeffectsnotallowed")
            || combined.contains("side-effect tools are disabled")
            || combined.contains("side effect tools are disabled") {
            return .expectedPolicyBlock
        }
        if combined.contains("invalidtheme") || combined.contains("invalid theme") {
            return .invalidArguments
        }
        return .unexpectedFailure
    }

    nonisolated static func isExpectedSideEffectDenial(_ error: Error) -> Bool {
        classify(error) == .expectedPolicyBlock
    }
}
