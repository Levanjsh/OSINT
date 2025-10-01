import Foundation

struct UsernameTarget: Identifiable, Codable {
    let id: UUID
    let name: String
    let urlTemplate: String
    let method: String
    let requiresHead: Bool
    let rateLimit: TimeInterval

    init(name: String, urlTemplate: String, method: String = "HEAD", requiresHead: Bool = true, rateLimit: TimeInterval = 1.0) {
        id = UUID()
        self.name = name
        self.urlTemplate = urlTemplate
        self.method = method
        self.requiresHead = requiresHead
        self.rateLimit = rateLimit
    }
}

struct UsernameConfig {
    static let defaults: [UsernameTarget] = [
        UsernameTarget(name: "GitHub", urlTemplate: "https://github.com/%@"),
        UsernameTarget(name: "GitLab", urlTemplate: "https://gitlab.com/%@"),
        UsernameTarget(name: "Twitter", urlTemplate: "https://twitter.com/%@", method: "GET", requiresHead: false),
        UsernameTarget(name: "Reddit", urlTemplate: "https://www.reddit.com/user/%@"),
        UsernameTarget(name: "Medium", urlTemplate: "https://medium.com/@%@", method: "GET", requiresHead: false),
        UsernameTarget(name: "DEV", urlTemplate: "https://dev.to/%@"),
        UsernameTarget(name: "StackOverflow", urlTemplate: "https://stackoverflow.com/users/story/%@", requiresHead: false, method: "GET"),
        UsernameTarget(name: "HackerNews", urlTemplate: "https://news.ycombinator.com/user?id=%@", method: "GET", requiresHead: false),
        UsernameTarget(name: "LinkedIn", urlTemplate: "https://www.linkedin.com/in/%@", method: "GET", requiresHead: false),
        UsernameTarget(name: "Keybase", urlTemplate: "https://keybase.io/%@")
    ]
}
