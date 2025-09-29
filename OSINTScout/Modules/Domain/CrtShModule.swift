import Foundation

struct CrtShModule: OSINTModule {
    let id = "domain.crtsh"
    let title = "Поддомены crt.sh"
    let description = "Извлечение поддоменов из публичных сертификатов"
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
        if let cached = context.cache.fetch(key: cacheKey, maxAge: 3600),
           let cachedResult = try? JSONDecoder().decode(ModuleResult.self, from: cached) {
            return cachedResult
        }

        let client = CrtShClient(http: context.http)
        let entries = try await client.fetch(domain: domain)
        let artifacts = entries.prefix(20).flatMap { entry -> [Artifact] in
            let names = entry.nameValue.components(separatedBy: "\n").filter { !$0.isEmpty }
            return names.map { name in
                Artifact(title: "Поддомен", value: name, context: "Сертификат: \(entry.commonName)")
            }
        }
        let summary = artifacts.isEmpty ? "Поддомены не найдены" : "Найдено \(artifacts.count) потенциальных поддоменов"
        let result = ModuleResult(moduleID: id, moduleName: title, entity: domain, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "https://crt.sh")!], raw: [:])
        if let data = try? JSONEncoder().encode(result) {
            context.cache.store(key: cacheKey, value: data)
        }
        return result
    }
}
