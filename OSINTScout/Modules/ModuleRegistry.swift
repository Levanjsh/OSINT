import Foundation
import OSLog

final class ModuleRegistry {
    private(set) var modules: [OSINTModule] = []
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
        registerDefaults()
    }

    private func registerDefaults() {
        modules = [
            DNSRecordsModule(),
            CrtShModule(),
            WaybackModule(),
            RDAPModule(),
            IPGeoModule(),
            EmailHygieneModule(),
            UsernamePresenceModule(),
            LocalMetadataModule(),
            NvdLookupModule()
        ]
    }
}
