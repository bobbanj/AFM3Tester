import FoundationModels

// MARK: - Structured Output Types

@Generable
struct ActionItem {
    var owner: String
    var task: String
    var deadline: String?
}

@Generable
struct MeetingSummary {
    var title: String
    var conciseSummary: String

    @Guide(description: "Overall meeting sentiment.", .anyOf(["positive", "neutral", "mixed", "negative"]))
    var sentiment: String

    var actionItems: [ActionItem]
    var risks: [String]
}

@Generable
struct SupportTicketClassification {
    var category: String

    @Guide(description: "Priority from 1 (lowest) to 5 (highest).", .range(1 ... 5))
    var priority: Int

    var summary: String
    var requiresHuman: Bool
}

// MARK: - Tool Argument Types

@Generable
struct GetProjectStatusArguments {
    @Guide(description: "Project codename to look up, such as Project Atlas, Project Orion, or Sample Workspace.")
    var projectName: String
}

@Generable
struct BudgetLineItem {
    var name: String
    var amount: Double
}

@Generable
struct CalculateBudgetArguments {
    @Guide(description: "Named budget line items with amounts.")
    var items: [BudgetLineItem]
}

@Generable
struct SetDemoThemeArguments {
    @Guide(description: "Demo appearance theme.", .anyOf(["light", "dark"]))
    var theme: String
}
