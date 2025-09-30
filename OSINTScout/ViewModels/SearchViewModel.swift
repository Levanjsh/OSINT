import Foundation

final class SearchViewModel {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func execute(entity: SearchEntity) {
        let logger = self.logger
        logger.log(entity)
    }
}

protocol Logger {
    func log(_ entity: SearchEntity)
}

struct SearchEntity {}
