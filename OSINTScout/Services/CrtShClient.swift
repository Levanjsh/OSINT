import Foundation

struct CrtShEntry: Decodable, Identifiable {
    let id: UUID = UUID()
    let commonName: String
    let nameValue: String
    let issuerName: String
    let entryTimestamp: String

    enum CodingKeys: String, CodingKey {
        case commonName = "common_name"
        case nameValue = "name_value"
        case issuerName = "issuer_name"
        case entryTimestamp = "entry_timestamp"
    }
}

final class CrtShClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func fetch(domain: String) async throws -> [CrtShEntry] {
        guard let encoded = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://crt.sh/?q=%25.\(encoded)&output=json") else {
            throw AppError.network("Неверный URL")
        }
        let data = try await http.getData(url)
        if data.isEmpty {
            return []
        }
        do {
            return try JSONDecoder().decode([CrtShEntry].self, from: data)
        } catch {
            throw AppError.decoding("crt.sh: \(error.localizedDescription)")
        }
    }
}
