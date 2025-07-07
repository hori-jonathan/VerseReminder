import Foundation

extension Verse {
    var verseNumber: String {
        id.components(separatedBy: ".").last ?? ""
    }

    var cleanedText: String {
        var stripped = content.stripHTML().trimmingCharacters(in: .whitespacesAndNewlines)
        stripped = stripped.trimmingLeadingParagraphSymbol()
        if let num = Int(verseNumber), stripped.hasPrefix("\(num) ") {
            return String(stripped.dropFirst("\(num) ".count))
        } else if let num = Int(verseNumber), stripped.hasPrefix("\(num)") {
            return String(stripped.dropFirst("\(num)".count)).trimmingCharacters(in: .whitespaces)
        } else {
            return stripped
        }
    }
}
