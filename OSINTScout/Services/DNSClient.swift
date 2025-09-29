import Foundation

protocol DNSResolving {
    func resolve(host: String, type: Int) async throws -> [DNSRecord]
}

struct DNSRecord: Decodable, Identifiable {
    let id: UUID
    let name: String
    let type: Int
    let data: String
    let ttl: Int?

    init(id: UUID = UUID(), name: String, type: Int, data: String, ttl: Int?) {
        self.id = id
        self.name = name
        self.type = type
        self.data = data
        self.ttl = ttl
    }

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case data = "data"
        case ttl = "TTL"
    }
}

struct DNSResponse: Decodable {
    let status: Int
    let answer: [DNSRecord]?
    let authority: [DNSRecord]?

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case answer = "Answer"
        case authority = "Authority"
    }
}

final class DNSClient: DNSResolving {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func resolve(host: String, type: Int) async throws -> [DNSRecord] {
        guard var components = URLComponents(string: "https://dns.google/resolve") else {
            throw AppError.network("Неверный URL")
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: host),
            URLQueryItem(name: "type", value: String(type))
        ]
        guard let url = components.url else { throw AppError.network("Неверный URL") }
        let response = try await http.get(url, responseType: DNSResponse.self)
        guard response.status == 0 else {
            throw AppError.network("DNS статус \(response.status)")
        }
        return response.answer ?? []
    }
}
