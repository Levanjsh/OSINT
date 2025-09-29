import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section(header: Text("Внешний вид")) {
                Toggle("Тёмная тема", isOn: Binding(
                    get: { viewModel.settings.appearance.prefersDarkMode },
                    set: { viewModel.updateAppearance(darkMode: $0) }
                ))
            }
            Section(header: Text("Этика"), footer: Text("OSINT Scout запрещает доксинг, преследование и другие незаконные действия.")) {
                Toggle("Этичный режим", isOn: Binding(
                    get: { viewModel.settings.ethics.ethicalModeEnabled },
                    set: { viewModel.toggleEthicalMode($0) }
                ))
            }
            Section(header: Text("Сеть")) {
                Stepper(value: Binding(
                    get: { viewModel.settings.network.maxConcurrentRequests },
                    set: { viewModel.updateNetwork(limit: $0, delay: viewModel.settings.network.minimumDelay) }
                ), in: 1...10) {
                    Text("Параллельных запросов: \(viewModel.settings.network.maxConcurrentRequests)")
                }
                Slider(value: Binding(
                    get: { viewModel.settings.network.minimumDelay },
                    set: { viewModel.updateNetwork(limit: viewModel.settings.network.maxConcurrentRequests, delay: $0) }
                ), in: 0...5, step: 0.5) {
                    Text("Минимальная задержка: \(viewModel.settings.network.minimumDelay, specifier: "%.1f") c")
                }
            }
            Section(header: Text("Интеграции"), footer: Text("Ключи хранятся в связке ключей macOS")) {
                Text("Censys, Shodan, VirusTotal — добавьте ключи для расширенных функций.")
                    .font(.footnote)
                SecureField("Censys API ID", text: Binding(
                    get: { viewModel.settings.integrations.censysAPIKey ?? "" },
                    set: { viewModel.updateAPIKey($0.isEmpty ? nil : $0, provider: .censysKey) }
                ))
                SecureField("Censys Secret", text: Binding(
                    get: { viewModel.settings.integrations.censysAPISecret ?? "" },
                    set: { viewModel.updateAPIKey($0.isEmpty ? nil : $0, provider: .censysSecret) }
                ))
                SecureField("Shodan API Key", text: Binding(
                    get: { viewModel.settings.integrations.shodanAPIKey ?? "" },
                    set: { viewModel.updateAPIKey($0.isEmpty ? nil : $0, provider: .shodan) }
                ))
                SecureField("VirusTotal API Key", text: Binding(
                    get: { viewModel.settings.integrations.virusTotalAPIKey ?? "" },
                    set: { viewModel.updateAPIKey($0.isEmpty ? nil : $0, provider: .virusTotal) }
                ))
            }
            Section(header: Text("Политика")) {
                Link("Лицензии", destination: URL(string: "https://opensource.org/licenses/MIT")!)
                Text("Использование только для законной обороны и исследования.")
            }
        }
        .padding()
        .navigationTitle("Настройки")
    }
}
