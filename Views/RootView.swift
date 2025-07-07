import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("setupComplete") private var setupComplete = false

    var body: some View {
        Group {
            if authViewModel.isLoading {
                ProgressView()
            } else if authViewModel.user != nil {
                if setupComplete {
                    ContentView()
                } else {
                    FirstTimeSetupView()
                }
            } else {
                VStack {
                    Text("Unable to sign in")
                    if let error = authViewModel.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                        let nsError = error as NSError
                        Text("Error code: \(nsError.code)")
                            .font(.footnote)
                    }
                    Button("Retry") {
                        authViewModel.signInAnonymouslyIfNeeded()
                    }
                    .padding(.top)
                }
            }
        }
        .preferredColorScheme(authViewModel.profile.theme.colorScheme)
        .tint(authViewModel.profile.theme.accentColor)
        .task {
            authViewModel.start()
        }
    }
}
