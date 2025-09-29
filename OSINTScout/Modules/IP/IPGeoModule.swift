import Foundation

struct IPGeoModule: OSINTModule {
    let id = "ip.geo"
    let title = "Геолокация IP"
    let description = "ip-api.com"
    let category = "IP"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        if case .ip = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .ip(ip) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let client = IPGeoClient(http: context.http)
        let response = try await client.lookup(ip: ip)
        var artifacts: [Artifact] = []
        if let country = response.country {
            artifacts.append(Artifact(title: "Страна", value: country))
        }
        if let city = response.city {
            artifacts.append(Artifact(title: "Город", value: city))
        }
        if let isp = response.isp {
            artifacts.append(Artifact(title: "ISP", value: isp))
        }
        if let org = response.org {
            artifacts.append(Artifact(title: "Организация", value: org))
        }
        if let asDescription = response.asDescription {
            artifacts.append(Artifact(title: "ASN", value: asDescription))
        }
        let summary = artifacts.isEmpty ? "Данные ip-api отсутствуют" : "Получены метаданные IP"
        return ModuleResult(moduleID: id, moduleName: title, entity: ip, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "http://ip-api.com")!], raw: [:])
    }
}
