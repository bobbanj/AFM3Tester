import Foundation
import FoundationModels

struct BudgetCalculatorTool: Tool {
    typealias Arguments = CalculateBudgetArguments

    let name = "calculateBudget"
    let description = "Totals named budget line items and returns a deterministic breakdown."

    func call(arguments: Arguments) async throws -> String {
        guard !arguments.items.isEmpty else {
            return "No line items provided. Supply at least one item with a name and amount."
        }

        var lines: [String] = []
        var total: Double = 0

        for item in arguments.items {
            let amount = item.amount
            total += amount
            lines.append(String(format: "- %@: $%.2f", item.name, amount))
        }

        let itemCount = arguments.items.count
        let average = total / Double(itemCount)

        var result = "Budget Calculation\n"
        result += lines.joined(separator: "\n")
        result += String(format: "\nSubtotal: $%.2f", total)
        result += String(format: "\nItem count: %d", itemCount)
        result += String(format: "\nAverage per item: $%.2f", average)
        return result
    }
}
