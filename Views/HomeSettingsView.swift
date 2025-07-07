import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .padding(.bottom, 4)

            QuickSettingsPanel()
                .environmentObject(authViewModel)
        }
        .padding(.top)
    }
}

