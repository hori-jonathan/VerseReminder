import FirebaseFirestore
import Foundation

/// Type of goal the reading plan is based on.
enum ReadingPlanGoalType: String, Codable {
    case finishByDate
    case chaptersPerDay
    case flexible
}

/// High level preset categories for building a reading plan
enum ReadingPlanPreset: String, CaseIterable, Codable {
    case fullBible
    case oldTestament
    case newTestament
    case gospels
    case prophets
    case wisdomBooks
    case epistles
    case prayers
    case custom
}

/// Node describing a single step in a reading plan tree
struct ReadingPlanNode: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var bookId: String?
    var chapter: Int?
    var children: [ReadingPlanNode] = []

    func flatten() -> [ReadingPlanNode] {
        [self] + children.flatMap { $0.flatten() }
    }
}

extension ReadingPlanNode {
    init?(dict: [String: Any]) {
        guard let title = dict["title"] as? String else { return nil }
        self.title = title
        id = dict["id"] as? String ?? UUID().uuidString
        bookId = dict["bookId"] as? String
        chapter = dict["chapter"] as? Int
        if let childData = dict["children"] as? [[String: Any]] {
            children = childData.compactMap { ReadingPlanNode(dict: $0) }
        }
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title
        ]
        if let bookId = bookId { dict["bookId"] = bookId }
        if let chapter = chapter { dict["chapter"] = chapter }
        if !children.isEmpty { dict["children"] = children.map { $0.dictionary } }
        return dict
    }
}

/// A more flexible reading plan model. It supports "finish by date" or
/// "chapters per day" styles as well as custom reading days and other
/// preferences. This is only a starting point and does not yet implement a
/// full scheduling engine.
struct ReadingPlan: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = "Reading Plan"
    var colorHex: String? = nil

    /// When the plan begins
    var startDate: Date = Date()

    /// If `goalType` is `.finishByDate` this value represents the desired end
    /// date. If `.chaptersPerDay` it is ignored.
    var finishBy: Date? = nil

    /// If `goalType` is `.chaptersPerDay` this is the number of chapters to read
    /// each reading day.
    var chaptersPerDay: Int? = nil

    /// Which days of the week the user intends to read. Values use three letter
    /// abbreviations ("Mon", "Tue", etc.).
    var readingDays: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// Plans default to non-linear reading; the property remains for backward
    /// compatibility but is always `true` for new plans.
    var allowNonLinear: Bool = true

    /// Notifications/encouragements enabled
    var notificationsEnabled: Bool = false

    /// How the goal is interpreted
    var goalType: ReadingPlanGoalType = .chaptersPerDay

    /// Optional preset category that defines the scope of reading
    var preset: ReadingPlanPreset = .fullBible

    /// Progress tree nodes describing the reading order
    var nodes: [ReadingPlanNode] = []

    /// Estimated completion based on the goal settings. For finish-by-date
    /// plans this simply returns `finishBy`. For chapter based plans the total
    /// number of Bible chapters (1189) is used with the per-day amount and
    /// reading days to estimate a completion date.
    var estimatedCompletion: Date {
        switch goalType {
        case .finishByDate:
            return finishBy ?? startDate
        case .chaptersPerDay:
            let daily = Double(chaptersPerDay ?? 1)
            let daysPerWeek = max(Double(readingDays.count), 1)
            let perWeek = daily * daysPerWeek
            let weeks = ceil(Double(1189) / max(perWeek, 1))
            return Calendar.current.date(byAdding: .day, value: Int(weeks * 7), to: startDate) ?? startDate
        case .flexible:
            return startDate
        }
    }

    /// Percentage completion based on chapters marked read in the given profile
    func completionPercentage(using profile: UserProfile) -> Double {
        let allNodes = nodes.flatMap { $0.flatten() }
        let total = allNodes.count
        guard total > 0 else { return 0 }
        let finished = allNodes.filter { node in
            if let bid = node.bookId, let chap = node.chapter {
                return profile.chaptersRead[bid]?.contains(chap) ?? false
            }
            return false
        }.count
        return Double(finished) / Double(total)
    }
}

extension ReadingPlan {
    init?(dict: [String: Any]) {
        guard let timestamp = dict["startDate"] as? Timestamp else { return nil }
        startDate = timestamp.dateValue()
        name = dict["name"] as? String ?? "Reading Plan"
        colorHex = dict["colorHex"] as? String
        id = dict["id"] as? String ?? UUID().uuidString
        if let finish = dict["finishBy"] as? Timestamp { finishBy = finish.dateValue() }
        chaptersPerDay = dict["chaptersPerDay"] as? Int
        readingDays = dict["readingDays"] as? [String] ?? ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        allowNonLinear = dict["allowNonLinear"] as? Bool ?? true
        notificationsEnabled = dict["notificationsEnabled"] as? Bool ?? false
        goalType = ReadingPlanGoalType(rawValue: dict["goalType"] as? String ?? "chaptersPerDay") ?? .chaptersPerDay
        preset = ReadingPlanPreset(rawValue: dict["preset"] as? String ?? "fullBible") ?? .fullBible
        if let nodeData = dict["nodes"] as? [[String: Any]] {
            nodes = nodeData.compactMap { ReadingPlanNode(dict: $0) }
        }
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "startDate": Timestamp(date: startDate),
            "readingDays": readingDays,
            "allowNonLinear": allowNonLinear,
            "notificationsEnabled": notificationsEnabled,
            "goalType": goalType.rawValue,
            "preset": preset.rawValue,
            "nodes": nodes.map { $0.dictionary }
        ]
        if let color = colorHex { dict["colorHex"] = color }
        if let finish = finishBy { dict["finishBy"] = Timestamp(date: finish) }
        if let perDay = chaptersPerDay { dict["chaptersPerDay"] = perDay }
        return dict
    }
}

