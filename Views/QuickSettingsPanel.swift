import SwiftUI

struct QuickSettingsPanel: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var showBiblePicker: Bool = true

    private let bibleOptions: [(name: String, id: String)] = [
        ("Douay-Rheims", "bible_dra.sqlite"),
        ("American Standard Version", "bible_asv.sqlite"),
        ("Darby Bible", "bible_dby.sqlite"),
        ("King James Version", "bible_kjv.sqlite"),
        ("Wycliffe Bible", "bible_wyc.sqlite")
    ]

    @State private var fontSizeValue: Double = 17
    @State private var spacingValue: Double = 8
    @State private var previewVerse: Verse?

    private var biblePicker: some View {
        Picker("Bible Version", selection: Binding(
            get: { authViewModel.profile.bibleId },
            set: { authViewModel.updateBibleId($0) })) {
            ForEach(bibleOptions, id: \.id) { opt in
                Text(opt.name).tag(opt.id)
            }
        }
        .pickerStyle(.menu)
    }

    private var textSizeSection: some View {
        VStack(alignment: .leading) {
            Text("Text Size")
                .font(.subheadline)
            Slider(value: $fontSizeValue, in: 14...24, step: 1) {
                Text("Text Size")
            } minimumValueLabel: {
                Text("A").font(.footnote)
            } maximumValueLabel: {
                Text("A").font(.title)
            }
            .onChange(of: fontSizeValue) { newValue in
                authViewModel.updateFontSize(FontSizeOption(value: newValue))
            }
        }
    }

    private var fontStyleSection: some View {
        VStack(alignment: .leading) {
            Text("Font Style")
                .font(.subheadline)
            HStack {
                ForEach(FontChoice.allCases, id: \.self) { choice in
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
    }

    private var verseSpacingSection: some View {
        VStack(alignment: .leading) {
            Text("Verse Spacing")
                .font(.subheadline)
            Slider(value: $spacingValue, in: 4...16, step: 1) {
                Text("Spacing")
            }
            .onChange(of: spacingValue) { newValue in
                authViewModel.updateVerseSpacing(VerseSpacingOption(value: newValue))
            }
        }
    }


    private var previewSection: some View {
        VStack(alignment: .leading) {
            Text("Preview")
                .font(.subheadline)
            Text(previewVerse?.content.stripHTML() ?? "Loading...")
                .font(authViewModel.profile.fontChoice.font(size: authViewModel.profile.fontSize.pointSize))
                .lineSpacing(authViewModel.profile.verseSpacing.spacing)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            if showBiblePicker {
                biblePicker
            }
            textSizeSection
            fontStyleSection
            verseSpacingSection
            previewSection
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            fontSizeValue = authViewModel.profile.fontSize.value
            spacingValue = authViewModel.profile.verseSpacing.value
            loadPreviewVerse()
        }
        .onChange(of: authViewModel.profile.bibleId) { _ in
            loadPreviewVerse()
        }
    }

    private func loadPreviewVerse() {
        BibleAPI.shared.fetchVerse(reference: "JHN.3.16", bibleId: authViewModel.profile.bibleId) { result in
            DispatchQueue.main.async {
                if case .success(let verse) = result {
                    self.previewVerse = verse
                }
            }
        }
    }
}

struct QuickSettingsPanel_Previews: PreviewProvider {
    static var previews: some View {
        QuickSettingsPanel()
            .environmentObject(AuthViewModel())
    }
}

