import SwiftUI

struct QuickSettingsPanel: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    private let bibleOptions: [(name: String, id: String)] = [
        ("DRA", "bible_dra.sqlite"),
        ("ASV", "bible_asv.sqlite"),
        ("DBY", "bible_dby.sqlite"),
        ("KJV", "bible_kjv.sqlite"),
        ("WYC", "bible_wyc.sqlite")
    ]

    @State private var fontSizeValue: Double = 1
    @State private var spacingValue: Double = 1

    private func sliderValue(for size: FontSizeOption) -> Double {
        switch size {
        case .small: return 0
        case .medium: return 1
        case .large: return 2
        }
    }

    private func fontSize(for value: Double) -> FontSizeOption {
        if value < 0.5 { return .small }
        else if value < 1.5 { return .medium }
        else { return .large }
    }

    private func sliderValue(for spacing: VerseSpacingOption) -> Double {
        switch spacing {
        case .compact: return 0
        case .regular: return 1
        case .roomy: return 2
        }
    }

    private func spacingOption(for value: Double) -> VerseSpacingOption {
        if value < 0.5 { return .compact }
        else if value < 1.5 { return .regular }
        else { return .roomy }
    }

    var body: some View {
        VStack(spacing: 20) {
            Picker("Bible Version", selection: Binding(
                get: { authViewModel.profile.bibleId },
                set: { authViewModel.updateBibleId($0) })) {
                ForEach(bibleOptions, id: .id) { opt in
                    Text(opt.name).tag(opt.id)
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading) {
                Text("Text Size")
                    .font(.subheadline)
                Slider(value: $fontSizeValue, in: 0...2, step: 1) {
                    Text("Text Size")
                } minimumValueLabel: {
                    Text("A").font(.footnote)
                } maximumValueLabel: {
                    Text("A").font(.title)
                }
                .onChange(of: fontSizeValue) { newValue in
                    authViewModel.updateFontSize(fontSize(for: newValue))
                }
            }

            VStack(alignment: .leading) {
                Text("Font Style")
                    .font(.subheadline)
                HStack {
                    ForEach(FontChoice.allCases, id: .self) { choice in
                        Button(action: {
                            authViewModel.updateFontChoice(choice)
                        }) {
                            Text("Aa")
                                .font(choice.font(size: 20))
                                .padding(8)
                                .background(authViewModel.profile.fontChoice == choice ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Verse Spacing")
                    .font(.subheadline)
                Slider(value: $spacingValue, in: 0...2, step: 1) {
                    Text("Spacing")
                }
                .onChange(of: spacingValue) { newValue in
                    authViewModel.updateVerseSpacing(spacingOption(for: newValue))
                }
            }

            VStack(alignment: .leading) {
                Text("Theme")
                    .font(.subheadline)
                HStack {
                    ForEach(AppTheme.allCases, id: .self) { theme in
                        Button(action: {
                            authViewModel.updateTheme(theme)
                        }) {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: authViewModel.profile.theme == theme ? 3 : 0)
                                )
                        }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Preview")
                    .font(.subheadline)
                Text("In the beginning God created the heavens and the earth.\nAnd the Spirit of God was hovering over the face of the waters.")
                    .font(authViewModel.profile.fontChoice.font(size: authViewModel.profile.fontSize.pointSize))
                    .lineSpacing(authViewModel.profile.verseSpacing.spacing)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            fontSizeValue = sliderValue(for: authViewModel.profile.fontSize)
            spacingValue = sliderValue(for: authViewModel.profile.verseSpacing)
        }
    }
}

struct QuickSettingsPanel_Previews: PreviewProvider {
    static var previews: some View {
        QuickSettingsPanel()
            .environmentObject(AuthViewModel())
    }
}

