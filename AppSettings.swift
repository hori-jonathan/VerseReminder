import SwiftUI

enum FontSizeOption: String, CaseIterable, Codable {
    case small, medium, large
    var pointSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 20
        }
    }
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

enum VerseSpacingOption: String, CaseIterable, Codable {
    case compact, regular, roomy
    var spacing: CGFloat {
        switch self {
        case .compact: return 4
        case .regular: return 8
        case .roomy: return 14
        }
    }
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
