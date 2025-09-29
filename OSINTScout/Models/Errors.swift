import Foundation

enum AppError: LocalizedError, Identifiable {
    case network(String)
    case decoding(String)
    case cache(String)
    case validation(String)
    case blockedByEthics
    case cancelled
    case unknown

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case let .network(message):
            return "Сетевая ошибка: \(message)"
        case let .decoding(message):
            return "Ошибка разбора данных: \(message)"
        case let .cache(message):
            return "Ошибка кэша: \(message)"
        case let .validation(message):
            return message
        case .blockedByEthics:
            return "Запрос отклонён политикой этики"
        case .cancelled:
            return "Запрос отменён"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

struct ToastData: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let message: String
}

struct LegalNotice: Identifiable {
    let id: UUID = UUID()
    let title = "Правовое уведомление"
    let message = "OSINT Scout предназначен только для пассивной разведки в целях кибербезопасности и соблюдения закона. Продолжая, вы подтверждаете, что не будете использовать приложение для доксинга, преследования или незаконной деятельности."
}
