import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignInSheet = false
    @State private var showReset = false

    var body: some View {
        List {
            if let user = authViewModel.user {
                if user.isAnonymous {
                    Button("Sign in to sync your progress") {
                        showSignInSheet = true
                    }
                } else {
                    Section(header: Text("Account")) {
                        Text("Signed in as \(user.email ?? user.uid)")
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    showReset = true
                } label: {
                    Text("Reset Account")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showSignInSheet) {
            SignInOptionsView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showReset) {
            ResetAccountView()
                .environmentObject(authViewModel)
        }
    }
}

struct SignInOptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailForm = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let message = errorMessage {
                    Text(message).foregroundColor(.red)
                }
                Button("Sign in with Google") {
                    authViewModel.linkWithGoogle { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                        } else {
                            dismiss()
                        }
                    }
                }
                Button("Sign in with Email") {
                    showEmailForm = true
                }
                .sheet(isPresented: $showEmailForm) {
                    NavigationView {
                        Form {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                            SecureField("Password", text: $password)
                            if let message = errorMessage {
                                Text(message).foregroundColor(.red)
                            }
                            Button("Link Account") {
                                authViewModel.linkWithEmail(email: email, password: password) { error in
                                    if let error = error {
                                        errorMessage = error.localizedDescription
                                    } else {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .navigationTitle("Email Sign In")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showEmailForm = false }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Sign In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}
