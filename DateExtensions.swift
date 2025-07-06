import Foundation

extension Date {
    /// e.g. "2024-07-06"
    var isoDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    /// e.g. "Mon" "Tue"
    var weekdayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
