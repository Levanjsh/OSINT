import Foundation
import OSLog

actor HTTPClientLimiter {
    private var lastRequestDate: Date?
    private var pendingCount = 0
    private let logger: Logger
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore, logger: Logger) {
        self.settingsStore = settingsStore
        self.logger = logger
    }

    func acquire() async {
        let settings = settingsStore.settings
        let minDelay = settings.network.minimumDelay
        if let lastDate = lastRequestDate {
            let elapsed = Date().timeIntervalSince(lastDate)
            if elapsed < minDelay {
                let wait = minDelay - elapsed
                logger.debug("Throttling request for \(wait, format: .fixed(precision: 2))s")
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
        while pendingCount >= settings.network.maxConcurrentRequests {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        pendingCount += 1
    }

    func release() {
        pendingCount = max(0, pendingCount - 1)
        lastRequestDate = Date()
    }
}

final class HTTPClient {
    private let session: URLSession
    private let limiter: HTTPClientLimiter
    private let logger: Logger
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore, logger: Logger) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = ["User-Agent": "OSINT-Scout/1.0 (research)"]
        session = URLSession(configuration: configuration)
        limiter = HTTPClientLimiter(settingsStore: settingsStore, logger: logger)
        self.settingsStore = settingsStore
        self.logger = logger
    }

    func get<T: Decodable>(_ url: URL, responseType: T.Type, cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> T {
        let data = try await request(url: url, method: "GET", body: nil, cachePolicy: cachePolicy)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(responseType, from: data)
        } catch {
            logger.error("Decoding error for \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.decoding(error.localizedDescription)
        }
    }

    func getData(_ url: URL, cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> Data {
        try await request(url: url, method: "GET", body: nil, cachePolicy: cachePolicy)
    }

    func headResponse(_ url: URL) async throws -> HTTPURLResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        return try await data(for: request).1
    }

    func request(url: URL, method: String, body: Data?, cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = cachePolicy
        request.httpBody = body
        return try await data(for: request).0
    }

    func requestWithResponse(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await data(for: request)
    }

    private func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        await limiter.acquire()
        defer { limiter.release() }

        let retryLimit = settingsStore.settings.network.retryLimit
        for attempt in 0...retryLimit {
            do {
                logger.debug("Request \(request.httpMethod ?? "GET", privacy: .public) \(request.url?.absoluteString ?? "", privacy: .public)")
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.network("Неизвестный ответ")
                }
                guard 200..<400 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 429 {
                        await exponentialBackoff(for: attempt)
                        continue
                    }
                    throw AppError.network("Код ответа \(httpResponse.statusCode)")
                }
                return (data, httpResponse)
            } catch is CancellationError {
                throw AppError.cancelled
            } catch {
                logger.error("Request failed: \(error.localizedDescription, privacy: .public)")
                if attempt == retryLimit {
                    throw AppError.network(error.localizedDescription)
                }
                await exponentialBackoff(for: attempt)
            }
        }
        throw AppError.unknown
    }

    private func exponentialBackoff(for attempt: Int) async {
        let delay = pow(2.0, Double(attempt)) * 0.5
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
