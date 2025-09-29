import Foundation

struct RDAPModule: OSINTModule {
    let id = "domain.rdap"
    let title = "RDAP"
    let description = "Регистрационные данные домена"
    let category = "Домены"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        if case .domain = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .domain(domain) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let cacheKey = "\(id)|\(domain)"
        if let cached = context.cache.fetch(key: cacheKey, maxAge: 7200), let result = try? JSONDecoder().decode(ModuleResult.self, from: cached) {
            return result
        }
        let client = RDAPClient(http: context.http)
        let response = try await client.lookup(domain: domain)
        let events = response.events?.compactMap { event -> Artifact? in
            guard let action = event.eventAction, let date = event.eventDate else { return nil }
            return Artifact(title: action, value: date)
        } ?? []
        let nameServers = response.nameServers?.compactMap { $0.ldhName } ?? []
        var artifacts = events
        artifacts.append(contentsOf: nameServers.map { Artifact(title: "NS", value: $0) })
        let summary = artifacts.isEmpty ? "RDAP данные ограничены" : "Получено \(artifacts.count) записей"
        let result = ModuleResult(moduleID: id, moduleName: title, entity: domain, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "https://rdap.org")!], raw: [:])
        if let data = try? JSONEncoder().encode(result) {
            context.cache.store(key: cacheKey, value: data)
        }
        return result
    }
}
