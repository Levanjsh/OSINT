import Foundation

struct NVDResponse: Decodable {
    let vulnerabilities: [NVDVulnerability]
}

struct NVDVulnerability: Decodable, Identifiable {
    let id = UUID()
    let cve: CVEItem

    struct CVEItem: Decodable {
        let id: String
        let sourceIdentifier: String?
        let published: String?
        let lastModified: String?
        let descriptions: [CveDescription]
        let metrics: MetricsContainer?
        let references: [CveReference]

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case sourceIdentifier
            case published
            case lastModified
            case descriptions
            case metrics
            case references
        }
    }

    struct CveDescription: Decodable {
        let lang: String
        let value: String
    }

    struct MetricsContainer: Decodable {
        let cvssMetricV31: [Metric]?

        struct Metric: Decodable {
            let cvssData: CvssData
        }
    }

    struct CvssData: Decodable {
        let baseScore: Double?
        let baseSeverity: String?
        let vectorString: String?
    }

    struct CveReference: Decodable, Identifiable {
        let id = UUID()
        let url: URL
        let source: String?
    }
}

final class NVDClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func search(keyword: String) async throws -> [NVDVulnerability] {
        guard let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=\(encoded)") else {
            throw AppError.network("Неверный URL")
        }
        let response = try await http.get(url, responseType: NVDResponse.self)
        return response.vulnerabilities
    }
}
