import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                ProgressView()
            } else if authViewModel.user != nil {
                ContentView()
            } else {
                Text("Unable to sign in")
            }
        }
    }
}
