import FirebaseFirestore
import Foundation

struct ReadingPlan: Codable {
    var startDate: Date
    var chaptersPerWeek: Int
    var notificationsEnabled: Bool

    var estimatedCompletion: Date {
        // 1189 chapters in the Bible
        let weeks = Double(1189) / Double(max(chaptersPerWeek, 1))
        return Calendar.current.date(byAdding: .day, value: Int(weeks * 7), to: startDate) ?? startDate
    }
}

extension ReadingPlan {
    init?(dict: [String: Any]) {
        guard let timestamp = dict["startDate"] as? Timestamp else { return nil }
        startDate = timestamp.dateValue()
        chaptersPerWeek = dict["chaptersPerWeek"] as? Int ?? 1
        notificationsEnabled = dict["notificationsEnabled"] as? Bool ?? false
    }

    var dictionary: [String: Any] {
        [
            "startDate": Timestamp(date: startDate),
            "chaptersPerWeek": chaptersPerWeek,
            "notificationsEnabled": notificationsEnabled
        ]
    }
}
