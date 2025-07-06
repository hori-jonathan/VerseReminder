import Foundation

// Configuration for the self-hosted Bible database API
private let baseUrl = "http://66.179.211.114:4005"
private let userId = "local-admin"
private let centralPassword = "supersecret"

struct Verse: Equatable {
    let reference: String
    let content: String
    let contextURL: URL?
    let id: String
}

enum BibleAPIError: Error {
    case invalidResponse
    case requestFailed
    case verseNotFound
    case noVersesLoaded
}

class BibleAPI {
    static let shared = BibleAPI()
    private init() {
        self.allVerseIds = BibleAPI.loadVerseIdsFromBundle()
    }

    private(set) var allVerseIds: [String] = []

    private static func loadVerseIdsFromBundle() -> [String] {
        guard let url = Bundle.main.url(forResource: "verse_ids_api", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let ids = try? JSONDecoder().decode([String].self, from: data)
        else {
            print("Failed to load verse_ids_api.json from bundle.")
            return []
        }
        print("Loaded \(ids.count) verse IDs.")
        return ids
    }

    // MARK: - Fetch a single verse
    func fetchVerse(reference: String, bibleId: String = defaultBibleId, completion: @escaping (Result<Verse, BibleAPIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/db/query") else {
            completion(.failure(.requestFailed))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(centralPassword, forHTTPHeaderField: "x-central-password")

        let payload: [String: Any] = [
            "user_id": userId,
            "db_file": bibleId,
            "sql": "SELECT * FROM verses WHERE id = '\(reference)';"
        ]

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(.requestFailed))
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(.requestFailed))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard
                    let rows = json?["rows"] as? [[String: Any]],
                    let verseData = rows.first,
                    let content = verseData["content"] as? String,
                    let reference = verseData["reference"] as? String
                else {
                    completion(.failure(.verseNotFound))
                    return
                }

                let id = verseData["id"] as? String ?? reference
                let verse = Verse(reference: reference, content: content, contextURL: nil, id: id)
                completion(.success(verse))
            } catch {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }

    // MARK: - Fetch random verse from all loaded IDs
    func fetchRandomVerse(bibleId: String = defaultBibleId, completion: @escaping (Result<Verse, BibleAPIError>) -> Void) {
        guard !allVerseIds.isEmpty else {
            completion(.failure(.noVersesLoaded))
            return
        }
        let randomRef = allVerseIds.randomElement()!
        fetchVerse(reference: randomRef, bibleId: bibleId, completion: completion)
    }

    // MARK: - Previous/Next navigation
    func fetchAdjacentVerse(currentVerseId: String, direction: String, bibleId: String = defaultBibleId, completion: @escaping (Result<Verse, BibleAPIError>) -> Void) {
        guard !allVerseIds.isEmpty,
              let idx = allVerseIds.firstIndex(of: currentVerseId) else {
            completion(.failure(.noVersesLoaded))
            return
        }
        let newIdx: Int
        if direction == "next" {
            newIdx = (idx + 1) % allVerseIds.count
        } else {
            newIdx = (idx - 1 + allVerseIds.count) % allVerseIds.count
        }
        let newRef = allVerseIds[newIdx]
        fetchVerse(reference: newRef, bibleId: bibleId, completion: completion)
    }
}

// MARK: - HTML Stripping Extension
extension String {
    func stripHTML() -> String {
        // Using NSAttributedString can crash when the markup is malformed.
        // Instead rely entirely on a regex pass to remove tags and then decode
        // a handful of common HTML entities. This avoids any unexpected
        // Objective-C exceptions while still returning readable text.

        let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
        let range = NSRange(location: 0, length: self.utf16.count)
        var stripped = regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "") ?? self

        // Decode some basic HTML entities the API commonly returns
        let entities: [String: String] = [
            "&quot;": "\"",
            "&apos;": "'",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&nbsp;": " "
        ]
        for (entity, replacement) in entities {
            stripped = stripped.replacingOccurrences(of: entity, with: replacement)
        }
        return stripped
    }
}
