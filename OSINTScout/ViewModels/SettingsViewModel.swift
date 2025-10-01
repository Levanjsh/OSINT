import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: Settings
    private let store: SettingsStore

    init(settingsStore: SettingsStore) {
        store = settingsStore
        settings = settingsStore.settings
        settingsStore.$settings.assign(to: &$settings)
    }

    func toggleEthicalMode(_ value: Bool) {
        store.update { settings in
            settings.ethics.ethicalModeEnabled = value
        }
    }

    func toggleFreeSources(_ value: Bool) {
        store.toggleFreeSourcesOnly(value)
    }

    func updateAppearance(darkMode: Bool) {
        store.update { settings in
            settings.appearance.prefersDarkMode = darkMode
        }
    }

    func updateNetwork(limit: Int, delay: TimeInterval) {
        store.update { settings in
            settings.network.maxConcurrentRequests = limit
            settings.network.minimumDelay = delay
        }
    }

    func updateAPIKey(_ value: String?, provider: APIProvider) {
        store.updateAPIKey(value, provider: provider)
    }
}
