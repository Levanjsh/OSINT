import Foundation

struct WaybackEntry: Decodable, Identifiable {
    let id = UUID()
    let timestamp: String
    let original: String
    let statuscode: String
}

final class WaybackClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func fetchSnapshots(for domain: String) async throws -> [WaybackEntry] {
        guard let encoded = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://web.archive.org/cdx/search/cdx?url=\(encoded)&output=json&fl=timestamp,original,statuscode&filter=statuscode:200&limit=50") else {
            throw AppError.network("Неверный URL")
        }
        let data = try await http.getData(url)
        guard !data.isEmpty else { return [] }
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let array = json as? [[Any]], array.count > 1 else { return [] }
        return array.dropFirst().compactMap { item -> WaybackEntry? in
            guard item.count >= 3,
                  let timestamp = item[0] as? String,
                  let original = item[1] as? String,
                  let statuscode = item[2] as? String else { return nil }
            return WaybackEntry(timestamp: timestamp, original: original, statuscode: statuscode)
        }
    }
}
