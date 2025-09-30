import Foundation

final class CSVExporter {
    func export(report: Report, ethicalMode: Bool) -> Data {
        var rows: [String] = ["module,title,artifact_title,artifact_value"]
        for section in report.sections {
            let artifacts = ethicalMode ? section.artifacts.filter { !$0.isSensitive } : section.artifacts
            if artifacts.isEmpty {
                rows.append("\(section.moduleID),\(escape(section.title)),,")
            }
            for artifact in artifacts {
                rows.append("\(section.moduleID),\(escape(section.title)),\(escape(artifact.title)),\(escape(artifact.value))")
            }
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    private func escape(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(where: { $0 == "," || $0 == "\n" || $0 == "\r" }) || escaped.contains("\"") {
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}
