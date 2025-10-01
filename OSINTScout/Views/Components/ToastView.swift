import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?

    func body(content: Content) -> some View {
        ZStack {
            content
            if let toast {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading) {
                            Text(toast.title)
                                .font(.headline)
                            Text(toast.message)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            toast = nil
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: toast)
    }
}

extension View {
    func toast(item: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: item))
    }
}
