import Foundation

struct RobotsModule: OSINTModule {
    let id = "domain.robots"
    let title = "robots.txt"
    let description = "Анализ robots.txt"
    let category = "Веб"
    let isFreeTier = true
    let fetcher: (URL, HTTPClient) async throws -> Data

    init(fetcher: @escaping (URL, HTTPClient) async throws -> Data = { url, client in
        try await client.getData(url)
    }) {
        self.fetcher = fetcher
    }

    func supports(_ entity: Entity) -> Bool {
        if case .domain = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .domain(domain) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let cacheKey = "\(id)|\(domain)"
        if let cached = context.cache.fetch(key: cacheKey, maxAge: 1800),
           let result = try? JSONDecoder().decode(ModuleResult.self, from: cached) {
            return result
        }
        let paths = ["https://\(domain)/robots.txt", "http://\(domain)/robots.txt"]
        var content: String?
        var sourceURL: URL?
        for path in paths {
            guard let url = URL(string: path) else { continue }
            do {
                let data = try await fetcher(url, context.http)
                if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    content = text
                    sourceURL = url
                    break
                }
            } catch {
                continue
            }
        }
        guard let text = content, let link = sourceURL else {
            throw AppError.network("robots.txt недоступен")
        }
        let lines = text.split(whereSeparator: \.isNewline)
        let parsedRules = lines.compactMap { line -> Artifact? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
            let parts = trimmed.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return nil }
            let key = parts[0]
            let value = parts[1]
            if key.lowercased() == "user-agent" || key.lowercased() == "allow" || key.lowercased() == "disallow" || key.lowercased() == "sitemap" {
                return Artifact(title: key.capitalized, value: value)
            }
            return nil
        }
        let artifacts = Array(parsedRules.prefix(20))
        let summary = artifacts.isEmpty ? "robots.txt не содержит ограничений" : "Найдено \(artifacts.count) правил"
        let result = ModuleResult(moduleID: id, moduleName: title, entity: domain, summary: summary, artifacts: artifacts, sourceLinks: [link], raw: [:])
        if let data = try? JSONEncoder().encode(result) {
            context.cache.store(key: cacheKey, value: data)
        }
        return result
    }
}
