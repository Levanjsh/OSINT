import Foundation

final class JSONExporter {
    func export(report: Report, ethicalMode: Bool) throws -> Data {
        var filteredReport = report
        if ethicalMode {
            filteredReport.sections = report.sections.map { section in
                let filteredArtifacts = section.artifacts.filter { !$0.isSensitive }
                return ReportSection(moduleID: section.moduleID, title: section.title, summary: section.summary, artifacts: filteredArtifacts, links: section.links, source: section.source)
            }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(filteredReport)
    }
}
