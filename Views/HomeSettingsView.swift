import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    private let bibleOptions: [(name: String, id: String)] = [
        ("ESV", "179568874c45066f-01"),
        ("KJV", "de4e12af7f28f599-02"),
        ("NIV", "06125adad2d5898a-01"),
        ("NKJV", "b4cb7bdb3da2f761-01"),
        ("NLT", "fae20f318bf5bc7c-02")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                Picker("Bible Version", selection: Binding(
                    get: { authViewModel.profile.bibleId },
                    set: { authViewModel.updateBibleId($0) })) {
                    ForEach(bibleOptions, id: \.id) { opt in
                        Text(opt.name).tag(opt.id)
                    }
                }
                .pickerStyle(.menu)

                Picker("Font Size", selection: Binding(
                    get: { authViewModel.profile.fontSize },
                    set: { authViewModel.updateFontSize($0) })) {
                    ForEach(FontSizeOption.allCases, id: \.self) { size in
                        Text(size.rawValue.capitalized).tag(size)
                    }
                }
                .pickerStyle(.menu)

                Picker("Font", selection: Binding(
                    get: { authViewModel.profile.fontChoice },
                    set: { authViewModel.updateFontChoice($0) })) {
                    ForEach(FontChoice.allCases, id: \.self) { font in
                        Text(font.rawValue.capitalized).tag(font)
                    }
                }
                .pickerStyle(.menu)

                Picker("Verse Spacing", selection: Binding(
                    get: { authViewModel.profile.verseSpacing },
                    set: { authViewModel.updateVerseSpacing($0) })) {
                    ForEach(VerseSpacingOption.allCases, id: \.self) { space in
                        Text(space.rawValue.capitalized).tag(space)
                    }
                }
                .pickerStyle(.menu)

                Picker("Theme", selection: Binding(
                    get: { authViewModel.profile.theme },
                    set: { authViewModel.updateTheme($0) })) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding(.top)
    }
}
