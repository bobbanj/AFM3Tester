import Foundation
import FoundationModels

enum DemoThemeError: Error, LocalizedError {
    case sideEffectsNotAllowed
    case invalidTheme(String)

    var errorDescription: String? {
        switch self {
        case .sideEffectsNotAllowed:
            "Side-effect tools are disabled until the user explicitly allows them."
        case .invalidTheme(let theme):
            "Invalid theme '\(theme)'. Allowed values: light, dark."
        }
    }
}

actor DemoThemeController {
    private(set) var currentTheme: String = "light"
    var allowSideEffects = false

    func setAllowSideEffects(_ allowed: Bool) {
        allowSideEffects = allowed
    }

    func applyTheme(_ theme: String) throws -> String {
        let normalized = theme.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized == "light" || normalized == "dark" else {
            throw DemoThemeError.invalidTheme(theme)
        }
        guard allowSideEffects else {
            throw DemoThemeError.sideEffectsNotAllowed
        }
        currentTheme = normalized
        return "Demo theme updated to \(normalized)."
    }
}

struct DemoThemeTool: Tool {
    typealias Arguments = SetDemoThemeArguments

    let controller: DemoThemeController

    let name = "setDemoTheme"
    let description = "Sets the local demo appearance to light or dark. Requires explicit user permission for side effects."

    func call(arguments: Arguments) async throws -> String {
        try await controller.applyTheme(arguments.theme)
    }
}
