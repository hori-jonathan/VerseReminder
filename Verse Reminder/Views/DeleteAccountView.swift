import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var isConfirmed: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "delete"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Type \"DELETE\" to remove your account data from our servers. This cannot be undone.")
                .multilineTextAlignment(.center)
            TextField("DELETE", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
            if isConfirmed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .transition(.scale)
            }
            Button(role: .destructive) {
                authViewModel.deleteAccount()
                dismiss()
            } label: {
                Text("Delete Account")
            }
            .disabled(!isConfirmed)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
