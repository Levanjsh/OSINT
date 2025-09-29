import Foundation
import SwiftUI
import Combine
import OSLog

struct Settings: Codable {
    struct Appearance: Codable {
        var prefersDarkMode: Bool

        var preferredColorScheme: ColorScheme? {
            prefersDarkMode ? .dark : nil
        }
    }

    struct Legal: Codable {
        var hasConsented: Bool
    }

    struct Ethics: Codable {
        var ethicalModeEnabled: Bool
        var blockDoxingPatterns: Bool
    }

    struct Network: Codable {
        var maxConcurrentRequests: Int
        var minimumDelay: TimeInterval
        var retryLimit: Int
    }

    struct Integrations: Codable {
        var censysAPIKey: String?
        var censysAPISecret: String?
        var shodanAPIKey: String?
        var virusTotalAPIKey: String?
    }

    var appearance: Appearance
    var legal: Legal
    var ethics: Ethics
    var network: Network
    var integrations: Integrations
    var freeSourcesOnly: Bool

    static let `default` = Settings(
        appearance: Appearance(prefersDarkMode: false),
        legal: Legal(hasConsented: false),
        ethics: Ethics(ethicalModeEnabled: true, blockDoxingPatterns: true),
        network: Network(maxConcurrentRequests: 5, minimumDelay: 0.5, retryLimit: 2),
        integrations: Integrations(censysAPIKey: nil, censysAPISecret: nil, shodanAPIKey: nil, virusTotalAPIKey: nil),
        freeSourcesOnly: true
    )
}

final class SettingsStore: ObservableObject {
    @Published private(set) var settings: Settings
    private let storageURL: URL
    private let queue = DispatchQueue(label: "settings.store.queue")
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        storageURL = directory.appendingPathComponent("settings.json")
        if let data = try? Data(contentsOf: storageURL), let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
            save()
        }
        settings.integrations.censysAPIKey = KeychainService.shared.get(APIProvider.censysKey.storageKey)
        settings.integrations.censysAPISecret = KeychainService.shared.get(APIProvider.censysSecret.storageKey)
        settings.integrations.shodanAPIKey = KeychainService.shared.get(APIProvider.shodan.storageKey)
        settings.integrations.virusTotalAPIKey = KeychainService.shared.get(APIProvider.virusTotal.storageKey)
    }

    func update(_ updateBlock: (inout Settings) -> Void) {
        queue.sync {
            updateBlock(&settings)
            save()
        }
    }

    func toggleFreeSourcesOnly(_ value: Bool) {
        update { settings in
            settings.freeSourcesOnly = value
        }
    }

    func setLegalConsent(_ consent: Bool) {
        update { settings in
            settings.legal.hasConsented = consent
        }
    }

    func updateAPIKey(_ value: String?, provider: APIProvider) {
        KeychainService.shared.set(value, for: provider.storageKey)
        update { settings in
            switch provider {
            case .censysKey:
                settings.integrations.censysAPIKey = value
            case .censysSecret:
                settings.integrations.censysAPISecret = value
            case .shodan:
                settings.integrations.shodanAPIKey = value
            case .virusTotal:
                settings.integrations.virusTotalAPIKey = value
            }
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(settings)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }
}

enum APIProvider {
    case censysKey
    case censysSecret
    case shodan
    case virusTotal

    var storageKey: String {
        switch self {
        case .censysKey:
            return "censys.api.key"
        case .censysSecret:
            return "censys.api.secret"
        case .shodan:
            return "shodan.api.key"
        case .virusTotal:
            return "virustotal.api.key"
        }
    }
}
