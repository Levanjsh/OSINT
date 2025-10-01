import Foundation

final class MarkdownExporter {
    func export(report: Report, ethicalMode: Bool) -> Data {
        var lines: [String] = []
        lines.append("# Отчёт OSINT Scout")
        lines.append("- Время: \(report.created.formatted())")
        lines.append("- Цель: \(report.target)")
        lines.append("- Хеш: \(report.identifier.uuidString)")
        lines.append("")
        lines.append("## Содержание")
        for section in report.sections {
            lines.append("- [\(section.title)](#\(section.anchor))")
        }
        lines.append("")
        for section in report.sections {
            lines.append("## \(section.title)")
            lines.append("Источник: \(section.source)")
            lines.append("")
            lines.append(section.summary)
            lines.append("")
            for artifact in section.artifacts where !artifact.isSensitive || !ethicalMode {
                lines.append("- **\(artifact.title)**: \(artifact.value)")
            }
            if !section.links.isEmpty {
                lines.append("")
                lines.append("### Ссылки")
                section.links.forEach { url in
                    lines.append("- \(url.absoluteString)")
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }
}
