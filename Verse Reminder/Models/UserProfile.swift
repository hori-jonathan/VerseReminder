import Foundation
import SwiftUI

struct UserProfile {
    var chaptersRead: [String: [Int]]
    var chaptersBookmarked: [String: [Int]]
    var lastRead: [String: [String: Int]]
    var readingPlan: ReadingPlan?
    var bookmarks: [String]
    var lastReadBookId: String?
    /// Map of ISO date strings (YYYY-MM-DD) to count of chapters read that day
    var dailyChapterCounts: [String: Int]
    /// User notes for entire chapters keyed by "BOOK.CHAPTER" ids
    var chapterNotes: [String: String]
    /// User notes for individual verses keyed by chapter id then verse number
    var verseNotes: [String: [String: String]]
    // App settings
    var bibleId: String
    var fontSize: FontSizeOption
    var fontChoice: FontChoice
    var verseSpacing: VerseSpacingOption
    var theme: AppTheme

    init(chaptersRead: [String: [Int]] = [:],
         chaptersBookmarked: [String: [Int]] = [:],
         lastRead: [String: [String: Int]] = [:],
         readingPlan: ReadingPlan? = nil,
         bookmarks: [String] = [],
         lastReadBookId: String? = nil,
         dailyChapterCounts: [String: Int] = [:],
         chapterNotes: [String: String] = [:],
         verseNotes: [String: [String: String]] = [:],
         bibleId: String = defaultBibleId,
         fontSize: FontSizeOption = FontSizeOption(),
         fontChoice: FontChoice = .system,
        verseSpacing: VerseSpacingOption = VerseSpacingOption(),
        theme: AppTheme = .dark) {
        self.chaptersRead = chaptersRead
        self.chaptersBookmarked = chaptersBookmarked
        self.lastRead = lastRead
        self.readingPlan = readingPlan
        self.bookmarks = bookmarks
        self.lastReadBookId = lastReadBookId
        self.dailyChapterCounts = dailyChapterCounts
        self.chapterNotes = chapterNotes
        self.verseNotes = verseNotes
        self.bibleId = bibleId
        self.fontSize = fontSize
        self.fontChoice = fontChoice
        self.verseSpacing = verseSpacing
        self.theme = theme
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
        let chapterNotes = dict["chapterNotes"] as? [String: String] ?? [:]
        let verseNotes = dict["verseNotes"] as? [String: [String: String]] ?? [:]
        let bibleId = dict["bibleId"] as? String ?? defaultBibleId
        let fontSizeVal = dict["fontSize"] as? Double ?? 17
        let fontSize = FontSizeOption(value: fontSizeVal)
        let fontChoice = FontChoice(rawValue: dict["fontChoice"] as? String ?? FontChoice.system.rawValue) ?? .system
        let verseSpacingVal = dict["verseSpacing"] as? Double ?? 8
        let verseSpacing = VerseSpacingOption(value: verseSpacingVal)
        let theme = AppTheme(rawValue: dict["theme"] as? String ?? AppTheme.dark.rawValue) ?? .dark
        self.init(chaptersRead: chaptersRead, chaptersBookmarked: chaptersBookmarked, lastRead: lastRead, readingPlan: plan, bookmarks: bookmarks, lastReadBookId: lastBook, dailyChapterCounts: dailyCounts, chapterNotes: chapterNotes, verseNotes: verseNotes, bibleId: bibleId, fontSize: fontSize, fontChoice: fontChoice, verseSpacing: verseSpacing, theme: theme)
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "chaptersRead": chaptersRead,
            "chaptersBookmarked": chaptersBookmarked,
            "lastRead": lastRead,
            "bookmarks": bookmarks,
            "dailyChapterCounts": dailyChapterCounts,
            "chapterNotes": chapterNotes,
            "verseNotes": verseNotes,
            "bibleId": bibleId,
            "fontSize": fontSize.value,
            "fontChoice": fontChoice.rawValue,
            "verseSpacing": verseSpacing.value,
            "theme": theme.rawValue
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
