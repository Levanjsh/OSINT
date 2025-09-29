import Foundation

struct DNSRecordsModule: OSINTModule {
    let id = "domain.dns"
    let title = "DNS записи"
    let description = "Разрешение A/AAAA/CNAME/MX/TXT/NS через публичный DNS Google"
    let category = "Домены"
    let makeClient: (HTTPClient) -> DNSResolving
    let isFreeTier = true

    init(makeClient: @escaping (HTTPClient) -> DNSResolving = { DNSClient(http: $0) }) {
        self.makeClient = makeClient
    }

    func supports(_ entity: Entity) -> Bool {
        if case .domain = entity { return true }
        return false
    }

    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult {
        guard case let .domain(domain) = entity else {
            throw AppError.validation("Неверный тип сущности")
        }
        let client = makeClient(context.http)
        async let aRecords = fetchRecords(client: client, domain: domain, type: 1)
        async let aaaaRecords = fetchRecords(client: client, domain: domain, type: 28)
        async let mxRecords = fetchRecords(client: client, domain: domain, type: 15)
        async let txtRecords = fetchRecords(client: client, domain: domain, type: 16)
        async let nsRecords = fetchRecords(client: client, domain: domain, type: 2)
        async let cnameRecords = fetchRecords(client: client, domain: domain, type: 5)

        let combined = try await [
            ("A", aRecords),
            ("AAAA", aaaaRecords),
            ("MX", mxRecords),
            ("TXT", txtRecords),
            ("NS", nsRecords),
            ("CNAME", cnameRecords)
        ]

        let artifacts = combined.flatMap { type, records -> [Artifact] in
            records.map { record in
                Artifact(title: "\(type) → \(record.name)", value: record.data, context: "TTL: \(record.ttl ?? 0)")
            }
        }

        let summary = artifacts.isEmpty ? "DNS записи не найдены" : "Найдено \(artifacts.count) DNS записей"
        return ModuleResult(moduleID: id, moduleName: title, entity: domain, summary: summary, artifacts: artifacts, sourceLinks: [URL(string: "https://dns.google")!], raw: [:])
    }

    private func fetchRecords(client: DNSResolving, domain: String, type: Int) async throws -> [DNSRecord] {
        do {
            return try await client.resolve(host: domain, type: type)
        } catch {
            return []
        }
    }
}
