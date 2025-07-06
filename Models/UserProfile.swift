import Foundation

struct UserProfile {
    var chaptersRead: [String: [Int]]
    var chaptersBookmarked: [String: [Int]]
    var lastRead: [String: [String: Int]]
    var readingPlan: ReadingPlan?
    var bookmarks: [String]
    var lastReadBookId: String?
    /// Map of ISO date strings (YYYY-MM-DD) to count of chapters read that day
    var dailyChapterCounts: [String: Int]

    init(chaptersRead: [String: [Int]] = [:],
         chaptersBookmarked: [String: [Int]] = [:],
         lastRead: [String: [String: Int]] = [:],
         readingPlan: ReadingPlan? = nil,
         bookmarks: [String] = [],
         lastReadBookId: String? = nil,
         dailyChapterCounts: [String: Int] = [:]) {
        self.chaptersRead = chaptersRead
        self.chaptersBookmarked = chaptersBookmarked
        self.lastRead = lastRead
        self.readingPlan = readingPlan
        self.bookmarks = bookmarks
        self.lastReadBookId = lastReadBookId
        self.dailyChapterCounts = dailyChapterCounts
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
        let bookmarks = dict["bookmarks"] as? [String] ?? []
        let lastBook = dict["lastReadBookId"] as? String
        let dailyCounts = dict["dailyChapterCounts"] as? [String: Int] ?? [:]
        self.init(chaptersRead: chaptersRead, chaptersBookmarked: chaptersBookmarked, lastRead: lastRead, readingPlan: plan, bookmarks: bookmarks, lastReadBookId: lastBook, dailyChapterCounts: dailyCounts)
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "chaptersRead": chaptersRead,
            "chaptersBookmarked": chaptersBookmarked,
            "lastRead": lastRead,
            "bookmarks": bookmarks,
            "dailyChapterCounts": dailyChapterCounts
        ]
        if let plan = readingPlan {
            dict["readingPlan"] = plan.dictionary
        }
        if let lastBook = lastReadBookId {
            dict["lastReadBookId"] = lastBook
        }
        return dict
    }

    var totalChaptersRead: Int {
        chaptersRead.values.reduce(0) { $0 + $1.count }
    }

    var todayChaptersRead: Int {
        dailyChapterCounts[Date().isoDateString] ?? 0
    }
}
