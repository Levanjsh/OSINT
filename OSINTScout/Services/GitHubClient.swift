import Foundation

struct GitHubSearchResponse<Item: Decodable>: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [Item]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

struct GitHubRepository: Decodable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let htmlURL: URL
    let description: String?
    let stargazersCount: Int
    let owner: GitHubUser

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case htmlURL = "html_url"
        case description
        case stargazersCount = "stargazers_count"
        case owner
    }
}

struct GitHubUser: Decodable {
    let login: String
}

struct GitHubCodeResult: Decodable, Identifiable {
    let id: Int
    let name: String
    let path: String
    let htmlURL: URL
    let repository: GitHubRepository

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case htmlURL = "html_url"
        case repository
    }
}

final class GitHubClient {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func searchRepositories(term: String) async throws -> GitHubSearchResponse<GitHubRepository> {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.github.com/search/repositories?q=\(encoded)") else {
            throw AppError.network("Неверный URL")
        }
        return try await http.get(url, responseType: GitHubSearchResponse<GitHubRepository>.self)
    }
}
