import Foundation
import FoundationModels

struct ToolInvocationRecord: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let toolName: String
    let argumentsJSON: String
    let result: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        toolName: String,
        argumentsJSON: String,
        result: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.toolName = toolName
        self.argumentsJSON = argumentsJSON
        self.result = result
        self.timestamp = timestamp
    }
}

@MainActor
@Observable
final class ToolInvocationLog {
    private(set) var records: [ToolInvocationRecord] = []
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    var invocationCount: Int {
        records.count
    }

    func record(toolName: String, arguments: some Generable, result: String) {
        recordRaw(
            toolName: toolName,
            argumentsJSON: describeGenerableArguments(arguments),
            result: result
        )
    }

    func record(toolName: String, arguments: some Encodable, result: String) {
        recordRaw(
            toolName: toolName,
            argumentsJSON: encodeEncodableArguments(arguments),
            result: result
        )
    }

    func recordRaw(toolName: String, argumentsJSON: String, result: String) {
        let entry = ToolInvocationRecord(
            toolName: toolName,
            argumentsJSON: argumentsJSON,
            result: result
        )
        records.append(entry)
    }

    func records(for toolName: String) -> [ToolInvocationRecord] {
        records.filter { $0.toolName == toolName }
    }

    func clear() {
        records.removeAll()
    }

    private func describeGenerableArguments(_ arguments: some Generable) -> String {
        String(describing: arguments.generatedContent)
    }

    private func encodeEncodableArguments(_ arguments: some Encodable) -> String {
        do {
            let data = try encoder.encode(AnyEncodable(arguments))
            return String(decoding: data, as: UTF8.self)
        } catch {
            return "{\"encodingError\":\"\(error.localizedDescription)\"}"
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: some Encodable) {
        encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
