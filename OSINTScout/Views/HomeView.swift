import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("OSINT Scout")
                    .font(.largeTitle)
                    .bold()
                Text("Этичная платформа пассивной разведки. Используйте только для защиты и обучения, соблюдая законы и политику источников.")
                    .font(.body)
                    .foregroundColor(.secondary)
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Label("Пассивные источники данных", systemImage: "eye")
                    Label("Кэширование и отчёты", systemImage: "doc.text")
                    Label("Экспорт в Markdown/JSON/CSV", systemImage: "square.and.arrow.down")
                    Label("Этичный режим и фильтры", systemImage: "hand.raised")
                }
                Spacer()
                Text("Версия 1.0.0")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Link("Документация", destination: URL(string: "https://github.com/example/osint-scout")!)
                }
            }
        }
    }
}
