import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showAdvanced: Bool
    @Binding var showContact: Bool
    @Binding var showPrivacy: Bool
    @State private var selectedTheme: AppTheme = .dark
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

            HStack(spacing: 40) {
                Button { showPrivacy = true } label: {
                    VStack {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                        Text("Privacy Policy")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button { showContact = true } label: {
                    VStack {
                        Image(systemName: "envelope")
                            .font(.title2)
                        Text("Contact Us")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button { showAdvanced = true } label: {
                    VStack {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        Text("Settings")
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
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

