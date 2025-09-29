import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showEthicsAlert = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    TextField("Введите цель", text: $viewModel.input)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { viewModel.scan() }
                        .focused($isInputFocused)
                    Picker("Тип", selection: $viewModel.selectedType) {
                        ForEach(Entity.EntityType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }
                Toggle(isOn: Binding(
                    get: { viewModel.freeSourcesOnly },
                    set: { viewModel.setFreeSourcesOnly($0) }
                )) {
                    Text("Только бесплатные источники")
                }
                Toggle(isOn: Binding(
                    get: { viewModel.isEthicalModeEnabled },
                    set: { viewModel.setEthicalMode($0) }
                )) {
                    Text("Этичный режим")
                }
                HStack {
                    Button(action: viewModel.scan) {
                        Label("Scan", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: viewModel.cancel) {
                        Label("Отмена", systemImage: "stop")
                    }
                    .buttonStyle(.bordered)
                }
                Button(action: { isInputFocused = true }) {
                    EmptyView()
                }
                .keyboardShortcut("k", modifiers: .command)
                .hidden()
                progressView
                List {
                    ForEach(viewModel.results) { result in
                        ModuleResultCard(result: result) {
                            viewModel.addToReport(result)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Поиск")
        }
        .alert(isPresented: $showEthicsAlert) {
            Alert(title: Text("Этика"), message: Text("Запрос заблокирован политикой приложения"), dismissButton: .default(Text("OK")))
        }
        .onChange(of: viewModel.state) { state in
            if case .failed(let error) = state, case .blockedByEthics = error {
                showEthicsAlert = true
            }
        }
    }

    @ViewBuilder
    private var progressView: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .running(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.linear)
        case .completed:
            Label("Готово", systemImage: "checkmark")
                .foregroundColor(.green)
        case .failed(let error):
            Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                .foregroundColor(.red)
        }
    }
}

struct ModuleResultCard: View {
    let result: ModuleResult
    let addToReport: () -> Void
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.moduleName)
                    .font(.headline)
                Spacer()
                Text(result.summary)
                    .font(.subheadline)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(result.artifacts) { artifact in
                        VStack(alignment: .leading) {
                            Text(artifact.title)
                                .font(.caption)
                            Text(artifact.value)
                                .font(.body)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            HStack {
                Button("Подробно") { showDetails = true }
                Button("Добавить в отчёт", action: addToReport)
                Spacer()
                ForEach(result.sourceLinks, id: \.self) { url in
                    Link(destination: url) {
                        Image(systemName: "link")
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showDetails) {
            ModuleDetailView(result: result)
        }
    }
}

struct ModuleDetailView: View {
    let result: ModuleResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(result.moduleName)
                .font(.title)
            Text(result.summary)
            Divider()
            List(result.artifacts) { artifact in
                VStack(alignment: .leading) {
                    Text(artifact.title)
                        .bold()
                    Text(artifact.value)
                }
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
