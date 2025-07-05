import FirebaseFirestore
import Foundation

struct ReadingPlan: Codable {
    var startDate: Date
    var dailyChapters: [String: Int]
    var notificationsEnabled: Bool

    var chaptersPerWeek: Int {
        dailyChapters.values.reduce(0, +)
    }

    var estimatedCompletion: Date {
        // 1189 chapters in the Bible
        let weeks = Double(1189) / Double(max(chaptersPerWeek, 1))
        return Calendar.current.date(byAdding: .day, value: Int(weeks * 7), to: startDate) ?? startDate
    }
}

extension ReadingPlan {
    init(startDate: Date = Date(), dailyChapters: [String: Int] = [:], notificationsEnabled: Bool = false) {
        self.startDate = startDate
        self.dailyChapters = dailyChapters
        self.notificationsEnabled = notificationsEnabled
    }

    init?(dict: [String: Any]) {
        guard let timestamp = dict["startDate"] as? Timestamp else { return nil }
        startDate = timestamp.dateValue()
        dailyChapters = dict["dailyChapters"] as? [String: Int] ?? [:]
        if dailyChapters.isEmpty {
            let perWeek = dict["chaptersPerWeek"] as? Int ?? 1
            dailyChapters = ["Mon": perWeek]
        }
        notificationsEnabled = dict["notificationsEnabled"] as? Bool ?? false
    }

    var dictionary: [String: Any] {
        [
            "startDate": Timestamp(date: startDate),
            "dailyChapters": dailyChapters,
            "notificationsEnabled": notificationsEnabled
        ]
    }
}
