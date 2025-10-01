import SwiftUI

struct ReportView: View {
    @ObservedObject var viewModel: ReportViewModel
    @State private var exportMessage: String?
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let report = viewModel.report {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Отчёт для \(report.target)")
                        .font(.title2)
                    Text("Создан: \(report.created.formatted())")
                        .font(.subheadline)
                    Text("ID: \(report.identifier.uuidString)")
                        .font(.footnote)
                }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(report.sections) { section in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.headline)
                                Text(section.summary)
                                ForEach(section.artifacts) { artifact in
                                    HStack {
                                        Text(artifact.title)
                                            .bold()
                                        Text(artifact.value)
                                            .textSelection(.enabled)
                                    }
                                }
                                if !section.links.isEmpty {
                                    HStack {
                                        ForEach(section.links, id: \.self) { url in
                                            Link(destination: url) {
                                                Text(url.absoluteString)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(12)
                        }
                    }
                }
                HStack {
                    Button("Markdown") {
                        if let url = viewModel.exportMarkdown() {
                            exportMessage = "Сохранено: \(url.path)"
                        }
                    }
                    Button("JSON") {
                        if let url = viewModel.exportJSON() {
                            exportMessage = "Сохранено: \(url.path)"
                        }
                    }
                    Button("CSV") {
                        if let url = viewModel.exportCSV() {
                            exportMessage = "Сохранено: \(url.path)"
                        }
                    }
                    Button("Очистить данные") {
                        environment.cache.clear()
                        viewModel.clear()
                    }
                    Button("Новый поиск") {
                        environment.selectedTab = .search
                    }
                    Spacer()
                }
                if let exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    Text("Отчёт пуст")
                        .font(.title3)
                    Text("Запустите поиск и добавьте данные в отчёт")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Отчёт")
    }
}
