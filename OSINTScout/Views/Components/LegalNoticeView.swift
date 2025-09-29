import SwiftUI

struct LegalNoticeView: View {
    let notice: LegalNotice
    var onAccept: () -> Void

    @State private var agreed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(notice.title)
                .font(.title2)
                .bold()
            ScrollView {
                Text(notice.message)
                    .font(.body)
                    .padding()
            }
            Toggle(isOn: $agreed) {
                Text("Я подтверждаю законное и этичное использование")
            }
            .toggleStyle(.switch)

            Button(action: onAccept) {
                Text("Продолжить")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!agreed)
        }
        .padding()
        .frame(width: 420, height: 360)
    }
}
