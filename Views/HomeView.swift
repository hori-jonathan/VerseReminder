import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Total chapters read: \(authViewModel.profile.totalChaptersRead)")
                    .font(.headline)
                Text("Reading goals coming soon...")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
