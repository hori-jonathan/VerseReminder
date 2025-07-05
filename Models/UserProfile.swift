import Foundation

struct UserProfile {
    var chaptersRead: [String: [Int]]
    var chaptersBookmarked: [String: [Int]]
    var lastRead: [String: [String: Int]]
    var readingPlan: ReadingPlan?
    var continuityBookmark: String?
    var lastReadBookId: String?

    init(chaptersRead: [String: [Int]] = [:],
         chaptersBookmarked: [String: [Int]] = [:],
         lastRead: [String: [String: Int]] = [:],
         readingPlan: ReadingPlan? = nil,
         continuityBookmark: String? = nil,
         lastReadBookId: String? = nil) {
        self.chaptersRead = chaptersRead
        self.chaptersBookmarked = chaptersBookmarked
        self.lastRead = lastRead
        self.readingPlan = readingPlan
        self.continuityBookmark = continuityBookmark
        self.lastReadBookId = lastReadBookId
    }
}

extension UserProfile {
    init?(dict: [String: Any]) {
        let chaptersRead = dict["chaptersRead"] as? [String: [Int]] ?? [:]
        let chaptersBookmarked = dict["chaptersBookmarked"] as? [String: [Int]] ?? [:]
        let lastRead = dict["lastRead"] as? [String: [String: Int]] ?? [:]
        var plan: ReadingPlan? = nil
        if let planData = dict["readingPlan"] as? [String: Any] {
            plan = ReadingPlan(dict: planData)
        }
        let bookmark = dict["continuityBookmark"] as? String
        let lastBook = dict["lastReadBookId"] as? String
        self.init(chaptersRead: chaptersRead, chaptersBookmarked: chaptersBookmarked, lastRead: lastRead, readingPlan: plan, continuityBookmark: bookmark, lastReadBookId: lastBook)
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "chaptersRead": chaptersRead,
            "chaptersBookmarked": chaptersBookmarked,
            "lastRead": lastRead
        ]
        if let plan = readingPlan {
            dict["readingPlan"] = plan.dictionary
        }
        if let bm = continuityBookmark {
            dict["continuityBookmark"] = bm
        }
        if let lastBook = lastReadBookId {
            dict["lastReadBookId"] = lastBook
        }
        return dict
    }

    var totalChaptersRead: Int {
        chaptersRead.values.reduce(0) { $0 + $1.count }
    }
}
