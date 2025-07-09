import SwiftUI

struct ResetAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var isConfirmed: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "confirmation"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Type \"Confirmation\" to reset your account. This will erase your progress.")
                .multilineTextAlignment(.center)
            TextField("Confirmation", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
            if isConfirmed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .transition(.scale)
            }
            Button("Reset Account") {
                authViewModel.resetAccount()
                dismiss()
            }
            .disabled(!isConfirmed)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}


