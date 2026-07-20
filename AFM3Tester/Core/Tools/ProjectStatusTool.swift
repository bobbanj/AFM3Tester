import Foundation
import FoundationModels

struct ProjectStatusTool: Tool {
    typealias Arguments = GetProjectStatusArguments

    let name = "getProjectStatus"
    let description = "Returns deterministic status information for known fictional demo projects."

    func call(arguments: Arguments) async throws -> String {
        let normalized = arguments.projectName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "project atlas", "atlas", "demo project":
            return """
            Project: Project Atlas
            Phase: Beta Hardening
            Health: Green
            Next Milestone: Public demo channel — April 2
            Blockers: None
            Owner: Platform Engineering
            """
        case "project orion", "orion":
            return """
            Project: Project Orion
            Phase: Integration
            Health: Yellow
            Next Milestone: Legacy sync deprecation — May 15
            Blockers: Structured logging gap in sync service
            Owner: Connectivity
            """
        case "sample workspace", "demo workspace", "workspace":
            return """
            Project: Sample Workspace
            Phase: Security Review
            Health: Green
            Next Milestone: Enterprise SSO documentation — March 28
            Blockers: Certificate rotation playbook pending legal review
            Owner: Security
            """
        default:
            return "Unknown project '\(arguments.projectName)'. Known projects: Project Atlas, Project Orion, Sample Workspace."
        }
    }
}
