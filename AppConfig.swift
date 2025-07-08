import Foundation

enum AppConfig {
    private static func value(forKey key: String) -> String {
        if let val = Bundle.main.infoDictionary?[key] as? String {
            return val
        }
        fatalError("Missing configuration value for \(key)")
    }

    static var bibleAPIBaseURL: String { value(forKey: "BIBLE_API_BASE_URL") }
    static var bibleAPIUserID: String { value(forKey: "BIBLE_API_USER_ID") }
    static var bibleAPIPassword: String { value(forKey: "BIBLE_API_PASSWORD") }
}
