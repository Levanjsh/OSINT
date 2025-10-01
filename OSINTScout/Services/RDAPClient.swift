import Foundation

struct RDAPResponse: Decodable {
    let objectClassName: String?
    let handle: String?
    let entities: [RdapEntity]?
    let events: [RdapEvent]?
    let nameServers: [RdapNameserver]?
}

struct RdapEntity: Decodable {
    let objectClassName: String?
    let handle: String?
    let vcardArray: [AnyCodable]?
}

struct RdapEvent: Decodable, Identifiable {
    let id = UUID()
    let eventAction: String?
    let eventDate: String?
}

struct RdapNameserver: Decodable, Identifiable {
    let id = UUID()
    let ldhName: String?
}

final class RDAPClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func lookup(domain: String) async throws -> RDAPResponse {
        guard domain.split(separator: ".").last != nil else {
            throw AppError.validation("Не удалось определить TLD")
        }
        let endpoint = "https://rdap.org/domain/\(domain)"
        guard let url = URL(string: endpoint) else {
            throw AppError.network("Неверный URL")
        }
        return try await http.get(url, responseType: RDAPResponse.self)
    }
}
