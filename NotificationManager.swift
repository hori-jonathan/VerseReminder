import Foundation
import UserNotifications

struct NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let messages = [
        "You have {n} chapters left to read today. Tap here to continue at {x}!",
        "Almost there! {n} more chapters to go. Pick up where you left off at {x}.",
        "Keep going—{n} chapters remain for today. Continue reading at {x}!",
        "Today’s goal is in reach! Read your remaining {n} chapters, starting at {x}.",
        "Don’t forget: you have {n} chapters left for today. Resume at {x}.",
        "Stay disciplined—just {n} chapters to finish today’s plan. Continue at {x}.",
        "Your reading journey continues! {n} chapters left—start with {x}.",
        "Psst! You’ve got {n} chapters to go. Tap here to pick up at {x}.",
        "A little progress each day. You still have {n} chapters for today—begin at {x}.",
        "You’re doing great! Just {n} chapters remain. Click here to continue at {x}."
    ]

    private func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if !granted {
                        print("Notification permission not granted")
                    }
                }
            }
        }
    }

    func updateSchedule(for profile: UserProfile) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard let plan = profile.readingPlan, plan.notificationsEnabled else { return }
        requestAuthorizationIfNeeded()

        let books = (oldTestamentCategories + newTestamentCategories).flatMap { $0.books }
        let bookLookup = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0.name) })
        let lastBookId = profile.lastReadBookId
        let lastPos = lastBookId.flatMap { profile.lastRead[$0] }
        let lastReference: String
        if let bid = lastBookId,
           let chapter = lastPos?["chapter"],
           let verse = lastPos?["verse"],
           let name = bookLookup[bid] {
            lastReference = "\(name) \(chapter):\(verse)"
        } else {
            lastReference = "your plan"
        }

        for offset in 0..<7 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let weekday = day.weekdayAbbrev
            let minutes = plan.notificationTimesByDay?[weekday] ?? plan.notificationTimeMinutes
            guard let m = minutes else { continue }
            let comps = DateComponents(year: Calendar.current.component(.year, from: day),
                                       month: Calendar.current.component(.month, from: day),
                                       day: Calendar.current.component(.day, from: day),
                                       hour: m / 60, minute: m % 60)
            let chaptersPlanned = plan.chaptersForDate(day)
            let read = profile.dailyChapterCounts[day.isoDateString] ?? 0
            let remaining = max(chaptersPlanned - read, 0)
            guard remaining > 0 else { continue }
            let template = messages.randomElement() ?? messages[0]
            let body = template
                .replacingOccurrences(of: "{n}", with: "\(remaining)")
                .replacingOccurrences(of: "{x}", with: lastReference)

            let content = UNMutableNotificationContent()
            content.title = "Reading Reminder"
            content.body = body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = "reminder-\(day.isoDateString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    /// Schedule a quick notification used for manual testing.
    func scheduleTestNotification() {
        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test of the notification system."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let id = "test-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule test notification: \(error)")
            }
        }
    }
}
