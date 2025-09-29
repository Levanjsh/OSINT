import Foundation

struct ReportSection: Identifiable, Codable {
    let id: UUID
    let moduleID: String
    let title: String
    let summary: String
    let artifacts: [Artifact]
    let links: [URL]
    let source: String
    let anchor: String

    init(id: UUID = UUID(), moduleID: String, title: String, summary: String, artifacts: [Artifact], links: [URL], source: String) {
        self.id = id
        self.moduleID = moduleID
        self.title = title
        self.summary = summary
        self.artifacts = artifacts
        self.links = links
        self.source = source
        self.anchor = title.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}

struct Report: Identifiable, Codable {
    let id: UUID
    let identifier: UUID
    let target: String
    let created: Date
    var sections: [ReportSection]

    init(target: String, sections: [ReportSection] = []) {
        id = UUID()
        identifier = UUID()
        self.target = target
        created = Date()
        self.sections = sections
    }
}
