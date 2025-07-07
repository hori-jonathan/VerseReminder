import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTheme: AppTheme = .light
    @State private var themeCheckTask: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .padding(.bottom, 4)

            QuickSettingsPanel()
                .environmentObject(authViewModel)

            Text("Theme")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach([AppTheme.light, AppTheme.dark], id: \.self) { theme in
                    Button(action: {
                        selectedTheme = theme
                        authViewModel.updateTheme(theme)
                    }) {
                        VStack {
                            Image(systemName: theme == .light ? "sun.max.fill" : "moon.stars.fill")
                                .font(.largeTitle)
                                .padding(.bottom, 8)
                            Text(theme.name)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .padding()
                        .background(selectedTheme == theme ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            themeCheckTask?.cancel()
            let task = DispatchWorkItem { selectedTheme = authViewModel.profile.theme }
            themeCheckTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
        .onChange(of: authViewModel.profile.theme) { newTheme in
            selectedTheme = newTheme
        }
        .padding(.top)
    }
}

