import Foundation
import Darwin

enum Entity: Hashable, Codable {
    case domain(String)
    case ip(String)
    case email(String)
    case username(String)

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    enum EntityType: String, CaseIterable, Identifiable, Codable {
        case domain
        case ip
        case email
        case username

        var id: String { rawValue }

        var title: String {
            switch self {
            case .domain:
                return "Домен"
            case .ip:
                return "IP"
            case .email:
                return "E-mail"
            case .username:
                return "Ник"
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EntityType.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch type {
        case .domain:
            self = .domain(value)
        case .ip:
            self = .ip(value)
        case .email:
            self = .email(value)
        case .username:
            self = .username(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .domain(value):
            try container.encode(EntityType.domain, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .ip(value):
            try container.encode(EntityType.ip, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .email(value):
            try container.encode(EntityType.email, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .username(value):
            try container.encode(EntityType.username, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }

    var rawValue: String {
        switch self {
        case let .domain(value), let .ip(value), let .email(value), let .username(value):
            return value
        }
    }

    var type: EntityType {
        switch self {
        case .domain:
            return .domain
        case .ip:
            return .ip
        case .email:
            return .email
        case .username:
            return .username
        }
    }

    static func parse(input: String, type: EntityType) throws -> Entity {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .domain:
            guard Validators.isValidDomain(trimmed) else {
                throw ValidationError.invalidDomain
            }
            return .domain(trimmed.lowercased())
        case .ip:
            guard Validators.isValidIPAddress(trimmed) else {
                throw ValidationError.invalidIP
            }
            return .ip(trimmed)
        case .email:
            guard Validators.isValidEmail(trimmed) else {
                throw ValidationError.invalidEmail
            }
            return .email(trimmed.lowercased())
        case .username:
            let normalized = trimmed.replacingOccurrences(of: " ", with: "").lowercased()
            guard Validators.isValidUsername(normalized) else {
                throw ValidationError.invalidUsername
            }
            return .username(normalized)
        }
    }
}

enum ValidationError: LocalizedError {
    case invalidDomain
    case invalidIP
    case invalidEmail
    case invalidUsername

    var errorDescription: String? {
        switch self {
        case .invalidDomain:
            return "Введите корректный домен"
        case .invalidIP:
            return "Введите корректный IP"
        case .invalidEmail:
            return "Введите корректный e-mail"
        case .invalidUsername:
            return "Введите корректный ник"
        }
    }
}

enum Validators {
    private static let domainRegex = try! NSRegularExpression(pattern: "^[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    private static let emailDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    private static let usernameRegex = try! NSRegularExpression(pattern: "^[A-Za-z0-9_.-]{3,32}$")

    static func isValidDomain(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        return domainRegex.firstMatch(in: value, options: [], range: range) != nil
    }

    static func isValidIPAddress(_ value: String) -> Bool {
        var ipv4 = in_addr()
        var ipv6 = in6_addr()
        if value.withCString({ inet_pton(AF_INET, $0, &ipv4) }) == 1 {
            return true
        }
        if value.withCString({ inet_pton(AF_INET6, $0, &ipv6) }) == 1 {
            return true
        }
        return false
    }

    static func isValidEmail(_ value: String) -> Bool {
        guard let detector = emailDetector else { return false }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return detector.matches(in: value, options: [], range: range).contains { result in
            guard result.resultType == .link, let url = result.url else { return false }
            return url.scheme == "mailto"
        }
    }

    static func isValidUsername(_ value: String) -> Bool {
        let range = NSRange(location: 0, length: value.utf16.count)
        return usernameRegex.firstMatch(in: value, options: [], range: range) != nil
    }
}
