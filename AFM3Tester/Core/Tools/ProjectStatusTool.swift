import Foundation
import FoundationModels

struct ProjectStatusTool: Tool {
    typealias Arguments = GetProjectStatusArguments

    let name = "getProjectStatus"
    let description = "Returns deterministic status information for known internal projects."

    func call(arguments: Arguments) async throws -> String {
        let normalized = arguments.projectName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "meridianos", "meridian os", "meridian":
            return """
            Project: MeridianOS
            Phase: Beta Hardening
            Health: Green
            Next Milestone: Public beta channel — April 2
            Blockers: None
            Owner: Platform Engineering
            """
        case "frizon":
            return """
            Project: Frizon
            Phase: Integration
            Health: Yellow
            Next Milestone: Legacy sync deprecation — May 15
            Blockers: Structured logging gap in sync service
            Owner: Connectivity
            """
        case "aegis":
            return """
            Project: Aegis
            Phase: Security Review
            Health: Green
            Next Milestone: Enterprise SSO documentation — March 28
            Blockers: Certificate rotation playbook pending legal review
            Owner: Security
            """
        default:
            return "Unknown project '\(arguments.projectName)'. Known projects: MeridianOS, Frizon, Aegis."
        }
    }
}
