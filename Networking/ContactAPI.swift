import Foundation

enum ContactAPIError: Error {
    case requestFailed
    case invalidResponse
}

class ContactAPI {
    static let shared = ContactAPI()
    private init() {}

    // Backend configuration values loaded from the app's Info.plist. Real
    // credentials should be supplied at build time and are not stored in the
    // repository.
    private let baseUrl = AppConfig.bibleAPIBaseURL
    private let userId = AppConfig.bibleAPIUserID
    private let password = AppConfig.bibleAPIPassword

    private func request(path: String, method: String = "POST", body: [String: Any]? = nil, completion: @escaping (Result<Data, ContactAPIError>) -> Void) {
        guard let url = URL(string: baseUrl + path) else {
            completion(.failure(.requestFailed))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if method == "POST" { req.addValue("application/json", forHTTPHeaderField: "Content-Type") }
        req.addValue(password, forHTTPHeaderField: "x-central-password")
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let data = data, err == nil {
                completion(.success(data))
            } else {
                completion(.failure(.requestFailed))
            }
        }.resume()
    }

    private func ensureSchema(completion: @escaping () -> Void) {
        guard let url = URL(string: "\(baseUrl)/db/column_info?user_id=\(userId)&db_file=contact.sqlite&table=messages") else {
            completion(); return
        }
        var req = URLRequest(url: url)
        req.addValue(password, forHTTPHeaderField: "x-central-password")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            var hasColumn = false
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let cols = json["columns"] as? [[String: Any]] {
                hasColumn = cols.contains { ($0["name"] as? String) == "created_at" }
            }
            if !hasColumn {
                let sql = "ALTER TABLE messages ADD COLUMN created_at TEXT"
                self.request(path: "/db/exec", body: [
                    "user_id": self.userId,
                    "db_file": "contact.sqlite",
                    "sql": sql
                ]) { _ in completion() }
            } else {
                completion()
            }
        }.resume()
    }

    func submitMessage(email: String, name: String, message: String, completion: @escaping (Result<Void, ContactAPIError>) -> Void) {
        ensureSchema {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let body: [String: Any] = [
                "user_id": self.userId,
                "db_file": "contact.sqlite",
                "table": "messages",
                "row": [
                    "email": email,
                    "name": name,
                    "message": message,
                    "created_at": timestamp
                ]
            ]
            self.request(path: "/db/insert_row", body: body) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
}
