import Foundation

struct NvdLookupModule: OSINTModule {
    let id = "vuln.nvd"
    let title = "NVD CVE"
    let description = "Поиск уязвимостей по ключевому слову"
    let category = "Уязвимости"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        switch entity {
        case .domain, .username:
            return false
        case let .email(email):
            return !email.isEmpty
        case let .ip(ip):
            return !ip.isEmpty
        }
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        let keyword = entity.rawValue
        let client = NVDClient(http: context.http)
        let vulns = try await client.search(keyword: keyword)
        let artifacts = vulns.prefix(10).flatMap { vuln -> [Artifact] in
            let description = vuln.cve.descriptions.first { $0.lang == "en" }?.value ?? ""
            let score = vuln.cve.metrics?.cvssMetricV31?.first?.cvssData.baseScore
            let severity = vuln.cve.metrics?.cvssMetricV31?.first?.cvssData.baseSeverity
            var artifacts: [Artifact] = [Artifact(title: "CVE", value: vuln.cve.id, context: description, isSensitive: false)]
            if let score {
                artifacts.append(Artifact(title: "CVSS", value: String(score), context: severity))
            }
            return artifacts
        }
        let summary = artifacts.isEmpty ? "Совпадений NVD не найдено" : "Обнаружено \(artifacts.count/2) записей NVD"
        let links = vulns.prefix(5).compactMap { vuln -> URL? in
            URL(string: "https://nvd.nist.gov/vuln/detail/\(vuln.cve.id)")
        }
        return ModuleResult(moduleID: id, moduleName: title, entity: keyword, summary: summary, artifacts: artifacts, sourceLinks: links, raw: [:])
    }
}
