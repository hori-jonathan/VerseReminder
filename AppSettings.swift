import SwiftUI

/// Continuous font size stored as a raw value in points.
struct FontSizeOption: Codable {
    var value: Double = 17
    var pointSize: CGFloat { CGFloat(value) }
}

enum FontChoice: String, CaseIterable, Codable {
    case system, serif, monospace
    func font(size: CGFloat) -> Font {
        switch self {
        case .system: return .system(size: size)
        case .serif: return .system(size: size, design: .serif)
        case .monospace: return .system(size: size, design: .monospaced)
        }
    }
}

/// Continuous verse spacing stored as a raw value of points between lines.
struct VerseSpacingOption: Codable {
    var value: Double = 8
    var spacing: CGFloat { CGFloat(value) }
}

enum AppTheme: String, CaseIterable, Codable {
    case light, dark, ocean, forest, sepia

    var name: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sepia: return "Sepia"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light, .ocean, .sepia: return .light
        case .dark, .forest: return .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .light: return .blue
        case .dark: return .orange
        case .ocean: return .teal
        case .forest: return .green
        case .sepia: return .brown
        }
    }
}
