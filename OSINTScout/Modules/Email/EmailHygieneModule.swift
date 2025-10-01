import Foundation

struct EmailHygieneModule: OSINTModule {
    let id = "email.hygiene"
    let title = "Почтовые политики"
    let description = "Проверка SPF/DKIM/DMARC"
    let category = "E-mail"
    let isFreeTier = true

    func supports(_ entity: Entity) -> Bool {
        if case let .email(email) = entity {
            return email.contains("@")
        }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .email(email) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let domain = email.split(separator: "@").last.map(String.init) ?? email
        let client = DNSClient(http: context.http)
        async let spfRecords = try? fetchTXT(client: client, host: domain)
        async let dmarcRecords = try? fetchTXT(client: client, host: "_dmarc.\(domain)")
        async let dkimRecords = try? fetchTXT(client: client, host: "default._domainkey.\(domain)")

        let results = await (
            spfRecords ?? [],
            dmarcRecords ?? [],
            dkimRecords ?? []
        )

        var artifacts: [Artifact] = []
        if !results.0.isEmpty {
            artifacts.append(Artifact(title: "SPF", value: results.0.joined(separator: "; ")))
        }
        if !results.1.isEmpty {
            artifacts.append(Artifact(title: "DMARC", value: results.1.joined(separator: "; ")))
        }
        if !results.2.isEmpty {
            artifacts.append(Artifact(title: "DKIM", value: results.2.joined(separator: "; ")))
        }
        let summary = artifacts.isEmpty ? "Политики SPF/DKIM/DMARC не найдены" : "Найдены политики почты"
        return ModuleResult(moduleID: id, moduleName: title, entity: email, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "https://dns.google")!], raw: [:])
    }

    private func fetchTXT(client: DNSClient, host: String) async throws -> [String] {
        let records = try await client.resolve(host: host, type: 16)
        return records.map { $0.data }
    }
}
