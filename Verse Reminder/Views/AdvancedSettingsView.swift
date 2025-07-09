import SwiftUI

struct AdvancedSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showReset = false
    @State private var showDelete = false

    var body: some View {
        List {
            Section {
                Button("Reset Account") { showReset = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                Button(role: .destructive) { showDelete = true } label: {
                    Text("Delete Account")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text("Both options reset your progress. Delete Account also removes all your data from our servers.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Advanced Settings")
        .sheet(isPresented: $showReset) {
            ResetAccountView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showDelete) {
            DeleteAccountView()
                .environmentObject(authViewModel)
        }
    }
}
