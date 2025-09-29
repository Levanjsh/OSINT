import Foundation
import OSLog

protocol OSINTModule {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    var category: String { get }
    var isFreeTier: Bool { get }

    func supports(_ entity: Entity) -> Bool
    func run(on entity: Entity, using context: ModuleContext) async throws -> ModuleResult
}

struct ModuleContext {
    let http: HTTPClient
    let cache: Cache
    let settings: Settings
    let logger: Logger
}
