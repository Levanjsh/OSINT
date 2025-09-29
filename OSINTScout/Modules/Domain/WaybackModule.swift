import Foundation

struct WaybackModule: OSINTModule {
    let id = "domain.wayback"
    let title = "Архив Wayback"
    let description = "Снимки из Wayback Machine"
    let category = "Веб"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        if case .domain = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .domain(domain) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let client = WaybackClient(http: context.http)
        let entries = try await client.fetchSnapshots(for: domain)
        let artifacts = entries.map { entry in
            Artifact(title: entry.timestamp, value: entry.original, context: "Код: \(entry.statuscode)")
        }
        let summary = artifacts.isEmpty ? "Снимки не найдены" : "Найдено \(artifacts.count) снимков"
        return ModuleResult(moduleID: id, moduleName: title, entity: domain, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "https://web.archive.org")!], raw: [:])
    }
}
