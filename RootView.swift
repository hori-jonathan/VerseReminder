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
                VStack {
                    Text("Unable to sign in")
                    if let error = authViewModel.error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                        let nsError = error as NSError
                        Text("Error code: \(nsError.code)")
                            .font(.footnote)
                    }
                }
            }
        }
        .task {
            authViewModel.start()
        }
    }
}
