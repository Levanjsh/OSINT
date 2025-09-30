import Foundation
import Combine
import OSLog

@MainActor
final class SearchViewModel: ObservableObject {
    enum State {
        case idle
        case running(Double)
        case completed
        case failed(AppError)
    }

    @Published var input: String = ""
    @Published var selectedType: Entity.EntityType = .domain
    @Published private(set) var results: [ModuleResult] = []
    @Published private(set) var state: State = .idle
    @Published var freeSourcesOnly: Bool
    @Published var isEthicalModeEnabled: Bool

    private let moduleRegistry: ModuleRegistry
    private let settingsStore: SettingsStore
    private let cache: Cache
    private let httpClient: HTTPClient
    private let logger: Logger
    private let reportManager: ReportManager
    private var runningTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(moduleRegistry: ModuleRegistry, settingsStore: SettingsStore, cache: Cache, httpClient: HTTPClient, logger: Logger, reportManager: ReportManager) {
        self.moduleRegistry = moduleRegistry
        self.settingsStore = settingsStore
        self.cache = cache
        self.httpClient = httpClient
        self.logger = logger
        self.reportManager = reportManager
        freeSourcesOnly = settingsStore.settings.freeSourcesOnly
        isEthicalModeEnabled = settingsStore.settings.ethics.ethicalModeEnabled
        settingsStore.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] settings in
                self?.freeSourcesOnly = settings.freeSourcesOnly
                self?.isEthicalModeEnabled = settings.ethics.ethicalModeEnabled
            }
            .store(in: &cancellables)
    }

    func scan() {
        runningTask?.cancel()
        results = []
        state = .idle
        do {
            let entity = try Entity.parse(input: input, type: selectedType)
            guard ethicsAllows(entity: entity) else {
                state = .failed(.blockedByEthics)
                return
            }
            runningTask = Task {
                await execute(entity: entity)
            }
        } catch {
            state = .failed(error as? AppError ?? .validation(error.localizedDescription))
        }
    }

    func cancel() {
        runningTask?.cancel()
        runningTask = nil
        state = .idle
    }

    func setFreeSourcesOnly(_ value: Bool) {
        freeSourcesOnly = value
        settingsStore.toggleFreeSourcesOnly(value)
    }

    func setEthicalMode(_ value: Bool) {
        isEthicalModeEnabled = value
        settingsStore.update { settings in
            settings.ethics.ethicalModeEnabled = value
        }
    }

    func addToReport(_ result: ModuleResult) {
        reportManager.add(result: result, target: result.entity)
    }

    private func execute(entity: Entity) async {
        let allowPaid = !settingsStore.settings.freeSourcesOnly
        let modules = moduleRegistry.modules.filter { module in
            module.supports(entity) && (module.isFreeTier || allowPaid)
        }
        let total = Double(modules.count)
        guard total > 0 else {
            await MainActor.run {
                self.state = .failed(.validation("Нет модулей для обработки"))
            }
            return
        }
        await MainActor.run {
            self.state = .running(0)
        }
        let context = ModuleContext(http: httpClient, cache: cache, settings: settingsStore.settings, logger: logger)
        var progress = 0.0
        var collected: [ModuleResult] = []
        let logger = self.logger
        let entityValue = entity.rawValue
        await withTaskGroup(of: ModuleResult?.self) { group in
            for module in modules {
                group.addTask {
                    if Task.isCancelled { return nil }
                    do {
                        let result = try await module.run(on: entity, using: context)
                        return result
                    } catch is CancellationError {
                        return nil
                    } catch {
                        logger.error("Module \(module.id, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                        return ModuleResult(moduleID: module.id, moduleName: module.title, entity: entityValue, summary: "Ошибка: \(error.localizedDescription)", artifacts: [], sourceLinks: [], raw: [:])
                    }
                }
            }

            for await result in group {
                if Task.isCancelled { break }
                progress += 1
                await MainActor.run {
                    self.state = .running(progress / total)
                }
                if let result {
                    collected.append(result)
                }
            }
        }
        await MainActor.run {
            self.results = collected.sorted { $0.moduleName < $1.moduleName }
            self.reportManager.ingest(results: collected, target: entity.rawValue)
            self.state = .completed
        }
    }

    private func ethicsAllows(entity: Entity) -> Bool {
        if !settingsStore.settings.ethics.blockDoxingPatterns { return true }
        let value = entity.rawValue
        if value.contains("address") || value.contains("phone") {
            return false
        }
        return true
    }
}
