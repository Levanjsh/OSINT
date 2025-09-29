import Foundation

struct IPGeoResponse: Decodable {
    let status: String
    let country: String?
    let regionName: String?
    let city: String?
    let isp: String?
    let org: String?
    let asDescription: String?
    let query: String

    enum CodingKeys: String, CodingKey {
        case status
        case country
        case regionName
        case city
        case isp
        case org
        case asDescription = "as"
        case query
    }
}

final class IPGeoClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func lookup(ip: String) async throws -> IPGeoResponse {
        guard let url = URL(string: "http://ip-api.com/json/\(ip)") else {
            throw AppError.network("Неверный URL")
        }
        let response = try await http.get(url, responseType: IPGeoResponse.self)
        guard response.status.lowercased() == "success" else {
            throw AppError.network("ip-api отказ")
        }
        return response
    }
}
