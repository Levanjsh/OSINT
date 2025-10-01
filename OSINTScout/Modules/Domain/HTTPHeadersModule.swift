import Foundation

struct HTTPHeadersModule: OSINTModule {
    let id = "domain.http_headers"
    let title = "HTTP заголовки"
    let description = "HEAD-запрос к веб-серверу"
    let category = "Веб"
    let isFreeTier = true
    let fetcher: (URLRequest, HTTPClient) async throws -> HTTPURLResponse

    init(fetcher: @escaping (URLRequest, HTTPClient) async throws -> HTTPURLResponse = { request, client in
        let (_, response) = try await client.requestWithResponse(request)
        return response
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

        let baseURLs = ["https://\(domain)", "http://\(domain)"]
        var response: HTTPURLResponse?
        for base in baseURLs {
            guard let url = URL(string: base) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5
            do {
                response = try await fetcher(request, context.http)
                break
            } catch {
                continue
            }
        }

        guard let httpResponse = response else {
            throw AppError.network("Не удалось получить заголовки")
        }

        let headers = httpResponse.allHeaderFields.compactMap { key, value -> Artifact? in
            guard let name = key as? String else { return nil }
            return Artifact(title: name, value: "\(value)")
        }
        let limited = Array(headers.prefix(10))
        let summary = "Статус \(httpResponse.statusCode). Заголовков: \(limited.count)"
        let result = ModuleResult(
            moduleID: id,
            moduleName: title,
            entity: domain,
            summary: summary,
            artifacts: limited,
            sourceLinks: [httpResponse.url].compactMap { $0 },
            raw: [:]
        )
        if let data = try? JSONEncoder().encode(result) {
            context.cache.store(key: cacheKey, value: data)
        }
        return result
    }
}
