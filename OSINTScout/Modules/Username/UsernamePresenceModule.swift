import Foundation

struct UsernamePresenceModule: OSINTModule {
    let id = "username.presence"
    let title = "Площадки"
    let description = "Проверка профилей по списку площадок"
    let category = "Ники"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        if case .username = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .username(username) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        var artifacts: [Artifact] = []
        for target in UsernameConfig.defaults {
            let urlString = String(format: target.urlTemplate, username)
            guard let url = URL(string: urlString) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = target.method
            do {
                let (_, response) = try await context.http.requestWithResponse(request)
                if (200..<400).contains(response.statusCode) {
                    artifacts.append(Artifact(title: target.name, value: urlString))
                }
                try await Task.sleep(nanoseconds: UInt64(target.rateLimit * 1_000_000_000))
            } catch {
                continue
            }
        }
        let summary = artifacts.isEmpty ? "Профили не найдены" : "Найдено \(artifacts.count) профилей"
        return ModuleResult(moduleID: id, moduleName: title, entity: username, summary: summary, artifacts: artifacts, sourceLinks: artifacts.compactMap { URL(string: $0.value) }, raw: [:])
    }
}
