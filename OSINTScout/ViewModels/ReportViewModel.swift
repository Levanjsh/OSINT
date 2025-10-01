import Foundation
import SwiftUI
import Combine
import OSLog
import AppKit

final class ReportManager: ObservableObject {
    @Published private(set) var report: Report?

    func ingest(results: [ModuleResult], target: String) {
        var current = report ?? Report(target: target)
        if current.target != target {
            current = Report(target: target)
        }
        let sections = results.map { result in
            ReportSection(moduleID: result.moduleID, title: result.moduleName, summary: result.summary, artifacts: result.artifacts, links: result.sourceLinks, source: result.moduleName)
        }
        current.sections = sections
        report = current
    }

    func add(result: ModuleResult, target: String) {
        var current = report ?? Report(target: target)
        if current.target != target {
            current = Report(target: target)
        }
        let section = ReportSection(moduleID: result.moduleID, title: result.moduleName, summary: result.summary, artifacts: result.artifacts, links: result.sourceLinks, source: result.moduleName)
        if let index = current.sections.firstIndex(where: { $0.moduleID == result.moduleID }) {
            current.sections[index] = section
        } else {
            current.sections.append(section)
        }
        report = current
    }

    func clear() {
        report = nil
    }
}

@MainActor
final class ReportViewModel: ObservableObject {
    @Published private(set) var report: Report?
    private let reportManager: ReportManager
    private let exporter: ExportCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(reportManager: ReportManager, exporter: ExportCoordinator) {
        self.reportManager = reportManager
        self.exporter = exporter
        report = reportManager.report
        reportManager.$report
            .receive(on: RunLoop.main)
            .sink { [weak self] report in
                self?.report = report
            }
            .store(in: &cancellables)
    }

    func exportMarkdown() -> URL? {
        guard let report else { return nil }
        return exporter.exportMarkdown(report: report)
    }

    func exportJSON() -> URL? {
        guard let report else { return nil }
        return exporter.exportJSON(report: report)
    }

    func exportCSV() -> URL? {
        guard let report else { return nil }
        return exporter.exportCSV(report: report)
    }

    func clear() {
        reportManager.clear()
        report = nil
    }
}

final class ExportCoordinator {
    private let markdown = MarkdownExporter()
    private let json = JSONExporter()
    private let csv = CSVExporter()
    private let logger: Logger

    init(reportManager: ReportManager, logger: Logger) {
        self.logger = logger
    }

    func exportMarkdown(report: Report) -> URL? {
        save(data: markdown.export(report: report, ethicalMode: true), filename: "report.md")
    }

    func exportJSON(report: Report) -> URL? {
        do {
            let data = try json.export(report: report, ethicalMode: true)
            return save(data: data, filename: "report.json")
        } catch {
            logger.error("JSON export failed: \(error.localizedDescription)")
            return nil
        }
    }

    func exportCSV(report: Report) -> URL? {
        save(data: csv.export(report: report, ethicalMode: true), filename: "report.csv")
    }

    private func save(data: Data, filename: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        do {
            try data.write(to: url)
            return url
        } catch {
            logger.error("Failed to save file: \(error.localizedDescription)")
            return nil
        }
    }
}
