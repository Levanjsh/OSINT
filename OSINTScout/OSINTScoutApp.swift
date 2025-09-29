import SwiftUI
import OSLog
import AppKit

@main
struct OSINTScoutApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
                .preferredColorScheme(environment.settingsStore.settings.appearance.preferredColorScheme)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Открыть README") {
                    environment.openReadMe()
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView(selection: $environment.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Домой", systemImage: "house.fill")
                }
                .tag(AppEnvironment.Tab.home)

            SearchView(viewModel: environment.searchViewModel)
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
                .tag(AppEnvironment.Tab.search)

            ReportView(viewModel: environment.reportViewModel)
                .tabItem {
                    Label("Отчёт", systemImage: "doc.text")
                }
                .tag(AppEnvironment.Tab.report)

            SettingsView(viewModel: environment.settingsViewModel)
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
                .tag(AppEnvironment.Tab.settings)
        }
        .toast(item: $environment.activeToast)
        .sheet(item: $environment.presentedLegalNotice) { notice in
            LegalNoticeView(notice: notice) {
                environment.settingsStore.setLegalConsent(true)
                environment.presentedLegalNotice = nil
            }
        }
        .onAppear {
            environment.prepareOnLaunch()
        }
    }
}

final class AppEnvironment: ObservableObject {
    enum Tab: Hashable {
        case home, search, report, settings
    }

    @Published var selectedTab: Tab = .home
    @Published var activeToast: ToastData?
    @Published var presentedLegalNotice: LegalNotice?

    let logger: Logger
    let httpClient: HTTPClient
    let cache: Cache
    let settingsStore: SettingsStore
    let moduleRegistry: ModuleRegistry

    let searchViewModel: SearchViewModel
    let reportViewModel: ReportViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        logger = Logger(subsystem: "com.osintscout.app", category: "app")
        settingsStore = SettingsStore(logger: logger)
        httpClient = HTTPClient(settingsStore: settingsStore, logger: logger)
        cache = Cache(logger: logger)
        moduleRegistry = ModuleRegistry(logger: logger)

        let reportManager = ReportManager()
        searchViewModel = SearchViewModel(moduleRegistry: moduleRegistry, settingsStore: settingsStore, cache: cache, httpClient: httpClient, logger: logger, reportManager: reportManager)
        reportViewModel = ReportViewModel(reportManager: reportManager, exporter: ExportCoordinator(reportManager: reportManager, logger: logger))
        settingsViewModel = SettingsViewModel(settingsStore: settingsStore)
    }

    func prepareOnLaunch() {
        if !settingsStore.settings.legal.hasConsented {
            presentedLegalNotice = LegalNotice()
        }
    }

    func presentError(_ error: Error) {
        activeToast = ToastData(title: "Ошибка", message: error.localizedDescription)
    }

    func openReadMe() {
        if let url = Bundle.main.url(forResource: "README", withExtension: "md") {
            NSWorkspace.shared.open(url)
        } else {
            activeToast = ToastData(title: "Файл не найден", message: "README недоступен в сборке")
        }
    }
}
