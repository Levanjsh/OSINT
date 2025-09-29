import Foundation

struct Artifact: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let value: String
    let context: String?
    let isSensitive: Bool

    init(id: UUID = UUID(), title: String, value: String, context: String? = nil, isSensitive: Bool = false) {
        self.id = id
        self.title = title
        self.value = value
        self.context = context
        self.isSensitive = isSensitive
    }
}

struct ModuleResult: Codable, Identifiable {
    let id: UUID
    let moduleID: String
    let moduleName: String
    let entity: String
    let summary: String
    let artifacts: [Artifact]
    let sourceLinks: [URL]
    let raw: [String: AnyCodable]
    let timestamp: Date

    init(id: UUID = UUID(), moduleID: String, moduleName: String, entity: String, summary: String, artifacts: [Artifact], sourceLinks: [URL], raw: [String: AnyCodable], timestamp: Date = Date()) {
        self.id = id
        self.moduleID = moduleID
        self.moduleName = moduleName
        self.entity = entity
        self.summary = summary
        self.artifacts = artifacts
        self.sourceLinks = sourceLinks
        self.raw = raw
        self.timestamp = timestamp
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map(AnyCodable.init))
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues(AnyCodable.init))
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
